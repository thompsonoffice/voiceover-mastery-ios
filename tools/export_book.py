#!/usr/bin/env python3
"""Parse content/VoiceOver-Mastery into VoiceOverMastery/Resources/book.json.

Chapter wording is copied. This script only splits the existing plain-text
structure (banner, all-caps headings, paragraphs, bullets, steps, sources).
It does not rewrite sentences or add gestures.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content" / "VoiceOver-Mastery"
OUT = ROOT / "VoiceOverMastery" / "Resources" / "book.json"

PARTS = [
    ("00-About", "about", 0, "About this guide", False),
    ("01-iPhone", "iphone", 1, "iPhone", True),
    ("02-iPad", "ipad", 2, "iPad", True),
    ("03-Mac", "mac", 3, "Mac", True),
    ("04-Apple-Watch", "watch", 4, "Apple Watch", True),
    ("05-Apple-TV", "tv", 5, "Apple TV", True),
    ("06-Vision-Pro", "vision", 6, "Apple Vision Pro", True),
    ("07-Apps-and-Practice", "apps", 7, "Apps and Practice", False),
]

HEADING_RE = re.compile(r"^[A-Z0-9][A-Z0-9'’,/&\-\(\):\". ]+$")
CHAPTER_RE = re.compile(r"^Chapter\s+([0-9]+\.[0-9]+)\.\s+(.+)$")
PART_RE = re.compile(r"^Part\s+([0-9]+)\.\s+(.+)$")
SMALL_WORDS = {"a", "an", "the", "and", "or", "of", "to", "in", "on", "for", "with", "from", "by", "if", "it"}


def words(text: str) -> list[str]:
    return re.findall(r"\S+", text)


def is_heading(line: str) -> bool:
    stripped = line.strip()
    if not stripped or len(stripped) > 100:
        return False
    letters = re.sub(r"[^A-Za-z]", "", stripped)
    if not letters or not letters.isupper():
        return False
    return HEADING_RE.fullmatch(stripped) is not None


def display_heading(source: str) -> str:
    """Sentence case so VoiceOver speaks the heading as words, not initials."""
    lower = source.lower()
    if not lower:
        return source
    return lower[0].upper() + lower[1:]


def slug(source: str) -> str:
    value = re.sub(r"[^a-z0-9]+", "-", source.lower()).strip("-")
    return (value[:60] or "section")


def kind_for(source: str) -> tuple[str, str]:
    mapping = {
        "OVERVIEW": ("overview", "overview"),
        "WHAT YOU'LL LEARN": ("learn", "what-youll-learn"),
        "PRACTICE EXERCISE": ("practice", "practice-exercise"),
        "QUICK REFERENCE SUMMARY": ("quickReference", "quick-reference"),
        "SOURCES": ("sources", "sources"),
    }
    if source in mapping:
        return mapping[source]
    return ("teaching", slug(source))


def split_banner(text: str) -> tuple[list[str], str]:
    lines = text.split("\n")
    bars = [index for index, line in enumerate(lines) if line.startswith("====")]
    if len(bars) < 2:
        raise SystemExit(f"missing banner in text starting {text[:80]!r}")
    banner = lines[: bars[1] + 1]
    body = "\n".join(lines[bars[1] + 1 :])
    if body.startswith("\n"):
        body = body[1:]
    if body.endswith("\n"):
        body = body[:-1]
    return banner, body


def parse_sections(body: str) -> list[dict]:
    lines = body.split("\n")
    headings: list[tuple[int, str]] = []
    for index, line in enumerate(lines):
        if is_heading(line):
            previous = lines[index - 1] if index else ""
            if previous.strip() != "":
                raise SystemExit(f"heading not preceded by a blank line: {line}")
            headings.append((index, line.strip()))
    if not headings:
        raise SystemExit("no headings found")
    if lines[: headings[0][0]] and any(line.strip() for line in lines[: headings[0][0]]):
        # Preamble before the first heading is kept as its own section by callers
        # that need it. Chapter files start at OVERVIEW.
        pass

    sections = []
    used_ids: set[str] = set()
    for position, (start, source) in enumerate(headings):
        end = headings[position + 1][0] if position + 1 < len(headings) else len(lines)
        chunk = lines[start + 1 : end]
        while chunk and chunk[0].strip() == "":
            chunk = chunk[1:]
        while chunk and chunk[-1].strip() == "":
            chunk = chunk[:-1]
        text = "\n".join(chunk)
        if not text.strip():
            raise SystemExit(f"empty section {source}")
        kind, section_id = kind_for(source)
        base = section_id
        suffix = 2
        while section_id in used_ids:
            section_id = f"{base}-{suffix}"
            suffix += 1
        used_ids.add(section_id)
        sections.append(
            {
                "id": section_id,
                "kind": kind,
                "sourceHeading": source,
                "heading": display_heading(source),
                "text": text,
            }
        )
    rebuilt: list[str] = []
    for section in sections:
        rebuilt.append(section["sourceHeading"])
        rebuilt.extend(words(section["text"]))
    # Headings are single tokens in the word list only when they contain no spaces.
    # Compare using the same word splitter on "HEADING\ntext" joined.
    flat: list[str] = []
    for section in sections:
        flat.extend(words(section["sourceHeading"]))
        flat.extend(words(section["text"]))
    if flat != words(body):
        raise SystemExit("section split dropped or changed words")
    for section in sections:
        if section["text"] not in body:
            raise SystemExit(f"section text is not an exact substring: {section['sourceHeading']}")
        if section["sourceHeading"] not in body:
            raise SystemExit(f"heading missing from body: {section['sourceHeading']}")
    return sections


def parse_chapter(path: Path, part_id: str) -> dict:
    source_text = path.read_text(encoding="utf-8")
    if "\r" in source_text:
        raise SystemExit(f"unexpected CR in {path}")
    banner, body = split_banner(source_text)
    title = None
    number = None
    for line in banner:
        match = CHAPTER_RE.match(line.strip())
        if match:
            number, title = match.group(1), match.group(2).strip()
    if not number or not title:
        raise SystemExit(f"no chapter title in {path}")
    sections = parse_sections(body)
    kinds = [section["kind"] for section in sections]
    for required in ("overview", "learn", "practice", "quickReference", "sources"):
        if required not in kinds:
            raise SystemExit(f"{path} missing {required}")
    if kinds[0] != "overview" or kinds[-1] != "sources":
        raise SystemExit(f"{path} section order is unexpected: {kinds}")
    return {
        "id": number,
        "title": title,
        "partID": part_id,
        "file": str(path.relative_to(CONTENT)),
        "sourceBody": body,
        "sections": sections,
    }


def parse_readme() -> dict:
    path = CONTENT / "README.txt"
    source_text = path.read_text(encoding="utf-8")
    _banner, body = split_banner(source_text)
    lines = body.split("\n")
    first_heading = next(index for index, line in enumerate(lines) if is_heading(line))
    preamble_lines = lines[:first_heading]
    while preamble_lines and preamble_lines[0].strip() == "":
        preamble_lines = preamble_lines[1:]
    while preamble_lines and preamble_lines[-1].strip() == "":
        preamble_lines = preamble_lines[:-1]
    preamble = "\n".join(preamble_lines)
    rest = "\n".join(lines[first_heading:])
    sections = [
        {
            "id": "welcome",
            "kind": "overview",
            "sourceHeading": "",
            "heading": "Read me",
            "text": preamble,
        }
    ]
    sections.extend(parse_sections(rest))
    # parse_sections checks rest only. Confirm the preamble is exact too.
    if preamble not in body:
        raise SystemExit("readme preamble is not an exact substring")
    return {"sections": sections, "sourceBody": body}


def parse_index() -> list[dict]:
    _banner, body = split_banner((CONTENT / "INDEX.txt").read_text(encoding="utf-8"))
    lines = body.split("\n")
    entries = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if line.strip() and not line.startswith(" ") and index + 1 < len(lines) and lines[index + 1].strip().startswith("See chapter"):
            term = line.strip()
            refs = re.findall(r"\d+\.\d+", lines[index + 1])
            if not refs:
                raise SystemExit(f"index entry has no chapters: {term}")
            entries.append({"term": term, "chapters": refs})
            index += 2
        else:
            index += 1
    if len(entries) < 50:
        raise SystemExit(f"expected the index, found {len(entries)} entries")
    return entries


def main() -> None:
    parts = []
    seen_ids: set[str] = set()
    for folder, part_id, number, platform, is_device in PARTS:
        directory = CONTENT / folder
        files = sorted(directory.glob("*.txt"))
        if not files:
            raise SystemExit(f"no chapters in {directory}")
        chapters = [parse_chapter(path, part_id) for path in files]
        for chapter in chapters:
            if chapter["id"] in seen_ids:
                raise SystemExit(f"duplicate chapter id {chapter['id']}")
            seen_ids.add(chapter["id"])
        part_title = None
        banner, _body = split_banner(files[0].read_text(encoding="utf-8"))
        for line in banner:
            match = PART_RE.match(line.strip())
            if match:
                part_title = match.group(2).strip()
                if int(match.group(1)) != number:
                    raise SystemExit(f"{folder} part number {match.group(1)} != {number}")
        if not part_title:
            raise SystemExit(f"no part title in {folder}")
        parts.append(
            {
                "id": part_id,
                "number": number,
                "title": part_title,
                "platform": platform,
                "isDevice": is_device,
                "chapters": chapters,
            }
        )

    index = parse_index()
    known = {chapter["id"] for part in parts for chapter in part["chapters"]}
    for entry in index:
        missing = [chapter_id for chapter_id in entry["chapters"] if chapter_id not in known]
        if missing:
            raise SystemExit(f"index {entry['term']!r} references missing chapters {missing}")

    chapters = [chapter for part in parts for chapter in part["chapters"]]
    if len(chapters) != 54:
        raise SystemExit(f"expected 54 chapters, found {len(chapters)}")
    word_count = sum(len(words(chapter["sourceBody"])) for chapter in chapters)
    book = {
        "title": "Access Mastery",
        "fullTitle": "Access Mastery: A Complete Guide to VoiceOver",
        "series": "SRTS: Screen Reader Training Suite",
        "edition": "First edition, November 2026",
        "author": "Hunter Thompson",
        "chapterCount": len(chapters),
        "wordCount": word_count,
        "parts": parts,
        "index": index,
        "readme": parse_readme(),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(book, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    qr_counts = {}
    for part in parts:
        count = 0
        for chapter in part["chapters"]:
            section = next(item for item in chapter["sections"] if item["kind"] == "quickReference")
            count += sum(1 for line in section["text"].split("\n") if line.startswith("- "))
        qr_counts[part["id"]] = count
    print(f"wrote {OUT} chapters={len(chapters)} words={word_count} index={len(index)}")
    print("quick reference bullets", json.dumps(qr_counts))


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
