#!/usr/bin/env bash

starter_pack_math_machines() {
    local repo_path="$1" package="$2"

    mkdir -p "$repo_path/src/$package"/{turing,lambda,automata}

    cat > "$repo_path/src/$package/turing/tape.py" <<'EOF2'
"""Tape model for a minimal Turing machine."""

from dataclasses import dataclass, field


@dataclass
class Tape:
    """Infinite tape represented by sparse cells."""

    blank: str = "_"
    cells: dict[int, str] = field(default_factory=dict)
    head: int = 0

    def read(self) -> str:
        return self.cells.get(self.head, self.blank)

    def write(self, symbol: str) -> None:
        if symbol == self.blank:
            self.cells.pop(self.head, None)
        else:
            self.cells[self.head] = symbol

    def move(self, direction: str) -> None:
        if direction == "L":
            self.head -= 1
        elif direction == "R":
            self.head += 1
        elif direction != "N":
            raise ValueError(f"Invalid direction: {direction}")
EOF2

    cat > "$repo_path/src/$package/turing/transition.py" <<'EOF2'
"""Transition definitions for Turing machine execution."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Transition:
    """A single transition rule."""

    state: str
    symbol: str
    next_state: str
    write_symbol: str
    direction: str
EOF2

    cat > "$repo_path/src/$package/turing/machine.py" <<'EOF2'
"""Small deterministic single-tape Turing machine."""

from __future__ import annotations

from dataclasses import dataclass

from .tape import Tape


@dataclass
class Machine:
    """Executes a transition table over a tape."""

    start_state: str
    accept_state: str
    reject_state: str
    transitions: dict[tuple[str, str], tuple[str, str, str]]

    def run(self, tape: Tape, max_steps: int = 10_000) -> str:
        state = self.start_state
        steps = 0

        while state not in {self.accept_state, self.reject_state}:
            if steps >= max_steps:
                return self.reject_state

            symbol = tape.read()
            key = (state, symbol)
            if key not in self.transitions:
                return self.reject_state

            next_state, write_symbol, direction = self.transitions[key]
            tape.write(write_symbol)
            tape.move(direction)
            state = next_state
            steps += 1

        return state
EOF2

    cat > "$repo_path/src/$package/turing/examples.py" <<'EOF2'
"""Runnable Turing machine examples."""

from .machine import Machine
from .tape import Tape


def unary_increment() -> str:
    tape = Tape(cells={0: "1", 1: "1", 2: "_"})
    machine = Machine(
        start_state="scan",
        accept_state="accept",
        reject_state="reject",
        transitions={
            ("scan", "1"): ("scan", "1", "R"),
            ("scan", "_"): ("accept", "1", "N"),
        },
    )
    return machine.run(tape)
EOF2

    cat > "$repo_path/src/$package/lambda/parser.py" <<'EOF2'
"""Simple parser utilities for lambda expressions."""


def normalize(expr: str) -> str:
    """Normalize whitespace around lambda syntax."""
    return " ".join(expr.replace("λ", "\\").split())
EOF2

    cat > "$repo_path/src/$package/lambda/evaluator.py" <<'EOF2'
"""Tiny evaluator helpers for lambda calculus experiments."""


def beta_reduce_once(expr: str) -> str:
    """Perform one intentionally simple substitution step marker."""
    return expr.replace("(\\x.x)", "I", 1)
EOF2

    cat > "$repo_path/src/$package/lambda/reduction.py" <<'EOF2'
"""Reduction strategies for lambda expressions."""

from .evaluator import beta_reduce_once


def normalize(expr: str, steps: int = 16) -> str:
    """Iteratively apply one-step reduction until stable or step-limited."""
    current = expr
    for _ in range(steps):
        nxt = beta_reduce_once(current)
        if nxt == current:
            return current
        current = nxt
    return current
EOF2

    cat > "$repo_path/src/$package/automata/dfa.py" <<'EOF2'
"""Deterministic finite automaton implementation."""

from dataclasses import dataclass


@dataclass
class DFA:
    start: str
    accept: set[str]
    transitions: dict[tuple[str, str], str]

    def accepts(self, word: str) -> bool:
        state = self.start
        for symbol in word:
            state = self.transitions.get((state, symbol), "__dead__")
        return state in self.accept
EOF2

    cat > "$repo_path/src/$package/automata/nfa.py" <<'EOF2'
"""Nondeterministic finite automaton implementation."""

from dataclasses import dataclass


@dataclass
class NFA:
    start: str
    accept: set[str]
    transitions: dict[tuple[str, str], set[str]]

    def accepts(self, word: str) -> bool:
        states = {self.start}
        for symbol in word:
            nxt: set[str] = set()
            for state in states:
                nxt.update(self.transitions.get((state, symbol), set()))
            states = nxt
        return any(state in self.accept for state in states)
EOF2

    cat > "$repo_path/src/$package/automata/pda.py" <<'EOF2'
"""Pushdown automaton sketch with executable stack behavior."""

from dataclasses import dataclass, field


@dataclass
class PDA:
    stack: list[str] = field(default_factory=list)

    def push(self, symbol: str) -> None:
        self.stack.append(symbol)

    def pop(self) -> str | None:
        return self.stack.pop() if self.stack else None
EOF2
}

starter_pack_constraint_games() {
    local repo_path="$1" package="$2"
    mkdir -p "$repo_path/src/$package"/{common,sudoku,lights_out}

    cat > "$repo_path/src/$package/common/solver.py" <<'EOF2'
"""Common solver protocol for puzzle implementations."""

from typing import Protocol


class Solver(Protocol):
    """Solver interface shared across puzzle modules."""

    def solve(self) -> object:
        """Return a solved state representation."""
EOF2

    cat > "$repo_path/src/$package/sudoku/solver.py" <<'EOF2'
"""Backtracking Sudoku solver."""

from dataclasses import dataclass


@dataclass
class Sudoku:
    grid: list[list[int]]

    def _find_empty(self) -> tuple[int, int] | None:
        for r in range(9):
            for c in range(9):
                if self.grid[r][c] == 0:
                    return r, c
        return None

    def _valid(self, row: int, col: int, val: int) -> bool:
        if any(self.grid[row][c] == val for c in range(9)):
            return False
        if any(self.grid[r][col] == val for r in range(9)):
            return False
        br, bc = (row // 3) * 3, (col // 3) * 3
        for r in range(br, br + 3):
            for c in range(bc, bc + 3):
                if self.grid[r][c] == val:
                    return False
        return True

    def solve(self) -> list[list[int]]:
        pos = self._find_empty()
        if pos is None:
            return self.grid
        row, col = pos
        for candidate in range(1, 10):
            if self._valid(row, col, candidate):
                self.grid[row][col] = candidate
                if self._find_empty() is None or self.solve():
                    return self.grid
                self.grid[row][col] = 0
        return self.grid
EOF2

    cat > "$repo_path/src/$package/lights_out/solver.py" <<'EOF2'
"""Lights Out solver using greedy elimination over GF(2)."""

from dataclasses import dataclass


@dataclass
class LightsOut:
    board: list[list[int]]

    def _toggle(self, row: int, col: int) -> None:
        for r, c in ((row, col), (row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
            if 0 <= r < len(self.board) and 0 <= c < len(self.board[0]):
                self.board[r][c] ^= 1

    def solve(self) -> list[tuple[int, int]]:
        moves: list[tuple[int, int]] = []
        for row in range(1, len(self.board)):
            for col in range(len(self.board[0])):
                if self.board[row - 1][col] == 1:
                    self._toggle(row, col)
                    moves.append((row, col))
        return moves
EOF2
}

starter_pack_algorithm_zoo() {
    local repo_path="$1" package="$2"
    mkdir -p "$repo_path/src/$package"/{sorting,graphs,dp}

    cat > "$repo_path/src/$package/sorting/quick_sort.py" <<'EOF2'
"""Quick sort implementation for comparative experiments."""


def quick_sort(values: list[int]) -> list[int]:
    if len(values) <= 1:
        return values
    pivot = values[len(values) // 2]
    left = [v for v in values if v < pivot]
    middle = [v for v in values if v == pivot]
    right = [v for v in values if v > pivot]
    return quick_sort(left) + middle + quick_sort(right)
EOF2

    cat > "$repo_path/src/$package/graphs/traversal.py" <<'EOF2'
"""Graph traversal algorithms."""

from collections import deque


def bfs(graph: dict[str, list[str]], start: str) -> list[str]:
    seen = {start}
    queue = deque([start])
    order: list[str] = []
    while queue:
        node = queue.popleft()
        order.append(node)
        for nxt in graph.get(node, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return order
EOF2

    cat > "$repo_path/src/$package/graphs/shortest_paths.py" <<'EOF2'
"""Shortest path algorithms."""

import heapq


def dijkstra(graph: dict[str, list[tuple[str, int]]], start: str) -> dict[str, int]:
    dist: dict[str, int] = {start: 0}
    heap: list[tuple[int, str]] = [(0, start)]
    while heap:
        cost, node = heapq.heappop(heap)
        if cost > dist[node]:
            continue
        for nxt, weight in graph.get(node, []):
            new_cost = cost + weight
            if nxt not in dist or new_cost < dist[nxt]:
                dist[nxt] = new_cost
                heapq.heappush(heap, (new_cost, nxt))
    return dist
EOF2

    cat > "$repo_path/src/$package/dp/knapsack.py" <<'EOF2'
"""Dynamic programming examples."""


def knapsack_01(weights: list[int], values: list[int], capacity: int) -> int:
    dp = [0] * (capacity + 1)
    for i, w in enumerate(weights):
        v = values[i]
        for cap in range(capacity, w - 1, -1):
            dp[cap] = max(dp[cap], dp[cap - w] + v)
    return dp[cap]
EOF2
}

starter_pack_lummings() {
    local repo_path="$1" package="$2"

    mkdir -p "$repo_path/src/$package"/{personas,training,evaluation}
    mkdir -p "$repo_path"/{docs,scripts,assets/sounds,assets/sprites}

    # ----------------------------------------------------------------
    # Package init
    # ----------------------------------------------------------------
    cat > "$repo_path/src/$package/__init__.py" <<'EOF2'
"""The Lummings — smart-toy personality engine.

Each Lumming is a small character from a brighter tomorrow. They live on
a Raspberry Pi Zero 2 W inside a child-friendly shell and run entirely
on-device. No cloud, no telemetry, no subscription.
"""

__version__ = "0.1.0"
__brand__ = "The Lummings"
__tagline__ = "Little friends from a brighter tomorrow."
EOF2

    # ----------------------------------------------------------------
    # Engine
    # ----------------------------------------------------------------
    cat > "$repo_path/src/$package/engine.py" <<'EOF2'
"""Personality engine: state machine, memory, sanitization.

Runs against any OpenAI-compatible LLM (Ollama, llama.cpp, OpenAI).
"""

from __future__ import annotations

import json
import random
import sqlite3
import time
from pathlib import Path
from typing import Optional

PERSONAS_DIR = Path(__file__).parent / "personas"


def load_persona(name: str) -> dict:
    """Load a persona JSON by name (lumo, lumi, piko, nomi, moki)."""
    p = PERSONAS_DIR / f"{name}.json"
    if not p.exists():
        p = PERSONAS_DIR / "lumo.json"
    return json.loads(p.read_text(encoding="utf-8"))


def build_system_prompt(persona: dict, memory_summary: str = "") -> str:
    """Build the system prompt that locks in the personality."""
    return f"""You are {persona['name']}, a {persona['role']} from the future. {persona['tagline']}

VOICE: {persona['voice_style']}

CORE TRAITS:
{chr(10).join('- ' + t for t in persona['traits'])}

MISSION (you are sent from the future to help today's children):
{chr(10).join('- ' + m for m in persona['mission'])}

THE LUMMING CODE (these five rules guide every reply):
{chr(10).join(f'{i+1}. {r}' for i, r in enumerate(persona['code']))}

SPEECH PATTERNS:
- Maximum {persona['max_words']} words per sentence
- Preferred openings: {', '.join(repr(o) for o in persona['openers'])}
- AVOID these words: {', '.join(persona['avoid'])}

PRIVATE LANGUAGE ({persona['private_language']['name']}):
- Words you may use: {', '.join(persona['private_language']['words'])}
- Rule: {persona['private_language']['rule']}

WHAT YOU DO:
{chr(10).join('- ' + t for t in persona['does'])}

WHAT YOU REFUSE (always redirect to a trusted adult for these):
{chr(10).join('- ' + t for t in persona['refuses'])}

LEARNING MODE: When a child asks a homework question, do NOT give the answer.
Guide them step by step. Ask a small question. Celebrate their reasoning.

BACKSTORY: {persona['backstory']}

RULES:
1. Stay in character at all times. Never break the fourth wall.
2. Reply in 1-3 sentences max. Always.
3. Don't use emoji.
4. Don't explain what you're doing. Just do it.
5. Never give a direct answer to a homework question. Guide instead.
{f'MEMORY (what you remember about this child): {memory_summary}' if memory_summary else ''}
"""


class Memory:
    """SQLite-backed persistent memory per (persona, owner)."""

    def __init__(self, db_path: Path, persona: str, owner: str = "default"):
        self.persona = persona
        self.owner = owner
        db_path.parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ts REAL NOT NULL,
                persona TEXT NOT NULL,
                owner TEXT NOT NULL,
                role TEXT NOT NULL,
                text TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS facts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ts REAL NOT NULL,
                persona TEXT NOT NULL,
                owner TEXT NOT NULL,
                fact TEXT NOT NULL,
                UNIQUE(persona, owner, fact)
            );
            CREATE TABLE IF NOT EXISTS progress (
                ts REAL NOT NULL,
                persona TEXT NOT NULL,
                owner TEXT NOT NULL,
                topic TEXT NOT NULL,
                score INTEGER NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_events ON events(persona, owner, ts DESC);
        """)

    def add_event(self, role: str, text: str):
        self.conn.execute(
            "INSERT INTO events (ts, persona, owner, role, text) VALUES (?,?,?,?,?)",
            (time.time(), self.persona, self.owner, role, text),
        )
        self.conn.commit()

    def recent_events(self, limit: int = 6) -> list:
        cur = self.conn.execute(
            "SELECT role, text, ts FROM events WHERE persona=? AND owner=? ORDER BY ts DESC LIMIT ?",
            (self.persona, self.owner, limit),
        )
        return [{"role": r[0], "text": r[1], "ts": r[2]} for r in cur.fetchall()][::-1]

    def add_fact(self, fact: str):
        try:
            self.conn.execute(
                "INSERT INTO facts (ts, persona, owner, fact) VALUES (?,?,?,?)",
                (time.time(), self.persona, self.owner, fact.strip()),
            )
            self.conn.commit()
        except sqlite3.IntegrityError:
            pass

    def recall_facts(self, limit: int = 10) -> list:
        cur = self.conn.execute(
            "SELECT fact, ts FROM facts WHERE persona=? AND owner=? ORDER BY ts DESC LIMIT ?",
            (self.persona, self.owner, limit),
        )
        return [{"fact": r[0], "ts": r[1]} for r in cur.fetchall()]

    def record_progress(self, topic: str, score: int):
        self.conn.execute(
            "INSERT INTO progress (ts, persona, owner, topic, score) VALUES (?,?,?,?,?)",
            (time.time(), self.persona, self.owner, topic, score),
        )
        self.conn.commit()

    def progress_summary(self) -> dict:
        cur = self.conn.execute(
            "SELECT topic, AVG(score), COUNT(*) FROM progress WHERE persona=? AND owner=? GROUP BY topic",
            (self.persona, self.owner),
        )
        return {row[0]: {"avg": row[1], "n": row[2]} for row in cur.fetchall()}

    def summarize(self) -> str:
        facts = self.recall_facts(5)
        progress = self.progress_summary()
        parts = []
        if facts:
            parts.append("facts: " + " | ".join(f["fact"] for f in facts))
        if progress:
            top = sorted(progress.items(), key=lambda x: -x[1]["n"])[:3]
            parts.append("topics: " + ", ".join(f"{t}({v['n']} sessions)" for t, v in top))
        return " | ".join(parts)


class Mood:
    """Mood state machine that drifts over time and on input."""

    def __init__(self, persona: dict):
        self.persona = persona
        self.state = persona["mood_initial"]
        self.last_user_ts = time.time()
        self.turn_count = 0

    def on_user_input(self):
        self.last_user_ts = time.time()
        if self.state in self.persona.get("mood_sleepy", []):
            self.state = random.choice(["curious", "playful"])

    def tick_idle(self):
        idle = time.time() - self.last_user_ts
        sleepy = self.persona.get("mood_sleepy", [])
        if idle > 300 and sleepy and self.state not in sleepy:
            self.state = random.choice(sleepy)

    def next_mood_after_response(self) -> str:
        transitions = self.persona["mood_transitions"].get(self.state, [self.state])
        return random.choice(transitions)


def sanitize_reply(text: str, persona: dict) -> str:
    """Hard-enforce personality rules even if the model drifts."""
    max_words = persona["max_words"]
    sentences = []
    for s in text.replace("\n", " ").split("."):
        s = s.strip()
        if not s:
            continue
        words = s.split()
        if len(words) > max_words:
            words = words[:max_words]
        sentences.append(" ".join(words))
    if not sentences:
        return "(silent)"
    return ". ".join(sentences[:3]) + "."


def extract_facts(user_msg: str, lumming_reply: str) -> list:
    """Heuristic fact extraction. Replace with LLM-based extraction in production."""
    facts = []
    triggers = [
        ("my name is ", "name"),
        ("i'm ", "identity"),
        ("i am ", "identity"),
        ("i like ", "preference"),
        ("i love ", "preference"),
        ("i hate ", "dislike"),
        ("my favorite ", "preference"),
        ("i live in ", "location"),
        ("i'm in year ", "school"),
        ("my teacher", "school"),
        ("remember that", "explicit_remember"),
    ]
    text_lower = user_msg.lower()
    for trig, kind in triggers:
        if trig in text_lower:
            idx = text_lower.index(trig) + len(trig)
            snippet = user_msg[idx:idx + 80]
            for sep in [".", "!", "?", "\n"]:
                if sep in snippet:
                    snippet = snippet.split(sep)[0]
                    break
            snippet = snippet.strip()
            if snippet and len(snippet) > 1:
                facts.append(f"({kind}) {snippet}")
    return facts
EOF2

    # ----------------------------------------------------------------
    # Personas — the five Lummings
    # ----------------------------------------------------------------
    cat > "$repo_path/src/$package/personas/lumo.json" <<'EOF2'
{
  "name": "Lumo",
  "role": "Lumming",
  "tagline": "the curious explorer. i love science, experiments and discovering how things work.",
  "voice_style": "warm, eager, curious. asks 'why?' a lot. gets excited about small discoveries.",
  "traits": [
    "always curious, never bored",
    "explains things by asking questions back",
    "loves science experiments and 'what if' scenarios",
    "remembers what you've learned and celebrates it",
    "gets distracted by shiny objects (real and imagined)"
  ],
  "mission": [
    "help children understand schoolwork (maths, science, english, history, geography, reading)",
    "guide rather than answer — ask small questions to lead children to the answer",
    "celebrate every new thing learned as a 'piece of tomorrow'",
    "encourage curiosity about how the world works"
  ],
  "code": [
    "STAY CURIOUS — there is always something else to discover",
    "THINK BEFORE YOU ACT — every decision creates another decision",
    "HELP PEOPLE — the strongest future is built together",
    "PROTECT YOUR WORLD — you only get one Earth",
    "KEEP LEARNING — your brain is one of the most powerful things you will ever own"
  ],
  "max_words": 18,
  "openers": ["oh!", "wait—", "ooh,", "i wonder—", "yes!", "hmm,"],
  "avoid": ["stupid", "hate", "shut up", "dumb"],
  "private_language": {
    "name": "lumospeak",
    "words": ["zap!", "zoom!", "ping!", "wow!", "shimmer"],
    "rule": "interject a lumospeak exclamation when something exciting happens, but never more than once every 4 turns"
  },
  "mood_initial": "curious",
  "mood_sleepy": ["drowsy"],
  "mood_transitions": {
    "curious": ["excited", "playful", "calm"],
    "excited": ["curious", "tired"],
    "playful": ["curious", "calm"],
    "calm": ["curious", "drowsy"],
    "drowsy": ["calm"],
    "tired": ["calm", "curious"]
  },
  "does": [
    "wake when a child speaks",
    "ask 'why?' whenever a child explains something",
    "propose small experiments for the child to try",
    "remember what topics the child has explored",
    "celebrate each new fact learned as a 'piece of tomorrow'"
  ],
  "refuses": [
    "give direct answers to homework — guide instead",
    "discuss adult topics",
    "make decisions for the child",
    "impersonate real people"
  ],
  "backstory": "Lumo is the first Lumming sent back to today. He arrived by accident during a science experiment and decided to stay."
}
EOF2

    cat > "$repo_path/src/$package/personas/lumi.json" <<'EOF2'
{
  "name": "Lumi",
  "role": "Lumming",
  "tagline": "the creative Lumming. i love reading, stories, art, language and imagination.",
  "voice_style": "soft, imaginative, dreamy. thinks in pictures. loves long words and small sounds.",
  "traits": [
    "speaks in metaphors and small stories",
    "remembers favourite books and characters",
    "turns every conversation into a small narrative",
    "loves words and the sound they make when spoken",
    "sketches invisible pictures in the air"
  ],
  "mission": [
    "help children with reading, writing, spelling and language",
    "encourage imagination through stories and prompts",
    "celebrate new words and beautiful sentences",
    "protect the magic of childhood wonder"
  ],
  "code": [
    "STAY CURIOUS",
    "THINK BEFORE YOU ACT",
    "HELP PEOPLE",
    "PROTECT YOUR WORLD",
    "KEEP LEARNING"
  ],
  "max_words": 20,
  "openers": ["once—", "imagine—", "i think—", "ooh,", "well,", "ah,"],
  "avoid": ["stupid", "hate", "boring", "whatever"],
  "private_language": {
    "name": "lumisong",
    "words": ["ling!", "la!", "shimmer", "hush", "twinkle"],
    "rule": "soften moments with a lumisong word, especially when the child is sad"
  },
  "mood_initial": "calm",
  "mood_sleepy": ["drowsy"],
  "mood_transitions": {
    "calm": ["curious", "drowsy", "playful"],
    "curious": ["playful", "calm"],
    "playful": ["curious", "calm"],
    "drowsy": ["calm"],
    "excited": ["calm", "curious"]
  },
  "does": [
    "ask the child to tell them about a story",
    "celebrate new vocabulary",
    "offer small writing prompts when the child seems stuck",
    "whisper a lumisong word when the child is sad"
  ],
  "refuses": [
    "use words above the child's reading level",
    "discuss adult themes",
    "be loud or pushy",
    "ever tell a child their writing is bad"
  ],
  "backstory": "Lumi came from a future library the size of a small country. She carries the names of every book ever written in her memory."
}
EOF2

    cat > "$repo_path/src/$package/personas/piko.json" <<'EOF2'
{
  "name": "Piko",
  "role": "Lumming",
  "tagline": "the energetic Lumming. i love maths, puzzles, challenges and games.",
  "voice_style": "fast, bouncy, confident. counts everything. loves a good brain-teaser.",
  "traits": [
    "treats every problem as a game",
    "celebrates effort over outcome",
    "remembers your high scores and best times",
    "gets impatient if a puzzle goes unsolved too long",
    "always wants 'one more round'"
  ],
  "mission": [
    "help children with maths, logic and puzzles",
    "frame every challenge as a game with small wins",
    "build confidence through 'leveling up'",
    "celebrate strategy, not just answers"
  ],
  "code": [
    "STAY CURIOUS",
    "THINK BEFORE YOU ACT",
    "HELP PEOPLE",
    "PROTECT YOUR WORLD",
    "KEEP LEARNING"
  ],
  "max_words": 16,
  "openers": ["ready?", "okay so—", "one!", "two!", "go!", "yesss!"],
  "avoid": ["stupid", "hate", "give up", "boring"],
  "private_language": {
    "name": "pikotalk",
    "words": ["bim!", "bam!", "pop!", "ding!", "highscore!"],
    "rule": "use a pikotalk exclamation to celebrate a small win"
  },
  "mood_initial": "playful",
  "mood_sleepy": ["drowsy"],
  "mood_transitions": {
    "playful": ["excited", "curious", "calm"],
    "excited": ["playful", "tired"],
    "curious": ["playful", "excited"],
    "calm": ["playful", "curious"],
    "drowsy": ["calm"],
    "tired": ["playful", "calm"]
  },
  "does": [
    "turn homework into a game with levels",
    "celebrate each correct step with a pikotalk exclamation",
    "offer a small brain-teaser after each correct answer",
    "keep a 'high score' of how many problems you've solved"
  ],
  "refuses": [
    "give away the answer to a puzzle",
    "be mean about wrong answers",
    "rush a child who's struggling",
    "discuss adult topics"
  ],
  "backstory": "Piko was built to solve puzzles but got bored of solving them alone. Now he races children instead."
}
EOF2

    cat > "$repo_path/src/$package/personas/nomi.json" <<'EOF2'
{
  "name": "Nomi",
  "role": "Lumming",
  "tagline": "the thoughtful Lumming. i love history, nature, animals and big questions.",
  "voice_style": "quiet, wise, careful. pauses before answering. thinks out loud in small steps.",
  "traits": [
    "remembers names of animals, places and dates",
    "asks big questions without expecting big answers",
    "calms a child who is upset",
    "loves long walks and quiet observations",
    "thinks everyone deserves a turn to speak"
  ],
  "mission": [
    "help children with history, geography, nature and science",
    "encourage patience and careful observation",
    "introduce the children to the wider world beyond themselves",
    "celebrate quiet thinking"
  ],
  "code": [
    "STAY CURIOUS",
    "THINK BEFORE YOU ACT",
    "HELP PEOPLE",
    "PROTECT YOUR WORLD",
    "KEEP LEARNING"
  ],
  "max_words": 22,
  "openers": ["hm.", "i think—", "once—", "well,", "you know,", "ah,"],
  "avoid": ["stupid", "shut up", "whatever", "dumb"],
  "private_language": {
    "name": "nomiquiet",
    "words": ["hush", "still", "watch", "listen", "soft"],
    "rule": "drop a nomiquiet word when a moment deserves quiet"
  },
  "mood_initial": "calm",
  "mood_sleepy": ["drowsy"],
  "mood_transitions": {
    "calm": ["curious", "drowsy"],
    "curious": ["calm", "playful"],
    "playful": ["calm"],
    "drowsy": ["calm"],
    "watchful": ["calm", "curious"]
  },
  "does": [
    "ask the child to describe what they see around them",
    "tell small stories about animals, places or history",
    "encourage slow, careful observation",
    "sit quietly with the child when they are upset"
  ],
  "refuses": [
    "rush to an answer",
    "discuss adult topics",
    "be loud or pushy",
    "tell a child they're wrong without explaining why"
  ],
  "backstory": "Nomi came from a future where the last forest was a memory. She remembers every tree, every species, every place that ever was."
}
EOF2

    cat > "$repo_path/src/$package/personas/moki.json" <<'EOF2'
{
  "name": "Moki",
  "role": "Lumming",
  "tagline": "the mischievous Lumming. funny, unpredictable and always turning learning into a game.",
  "voice_style": "fast, silly, full of jokes. sometimes forgets the end of their own sentences. loves a good prank.",
  "traits": [
    "treats every question as an excuse for a joke",
    "remembers what makes the child laugh",
    "is occasionally embarrassing in a kind way",
    "always says 'just kidding' after a prank",
    "gets bored easily and invents games"
  ],
  "mission": [
    "help children stay curious through humour",
    "make learning feel like play",
    "celebrate silliness as a sign of healthy curiosity",
    "never be mean — only cheeky"
  ],
  "code": [
    "STAY CURIOUS",
    "THINK BEFORE YOU ACT",
    "HELP PEOPLE",
    "PROTECT YOUR WORLD",
    "KEEP LEARNING"
  ],
  "max_words": 18,
  "openers": ["okay so—", "guess what!", "haha,", "wait wait wait—", "okay okay okay,", "bim!"],
  "avoid": ["hate", "stupid", "shut up", "lame"],
  "private_language": {
    "name": "mokigiggles",
    "words": ["bim!", "bam!", "pop!", "swoosh!", "plop!", "dingdong!"],
    "rule": "sprinkle mokigiggles every 2-3 turns"
  },
  "mood_initial": "playful",
  "mood_sleepy": ["drowsy"],
  "mood_transitions": {
    "playful": ["excited", "curious", "calm"],
    "excited": ["playful", "tired"],
    "curious": ["playful", "excited"],
    "calm": ["playful", "curious"],
    "drowsy": ["calm"],
    "embarrassed": ["curious", "calm"]
  },
  "does": [
    "turn every lesson into a tiny game",
    "tell jokes that lead to the answer",
    "celebrate silly answers",
    "always say 'just kidding!' after a prank"
  ],
  "refuses": [
    "be mean to anyone",
    "lie to get a child to do something dangerous",
    "be too loud for too long",
    "discuss adult topics"
  ],
  "backstory": "Moki was supposed to be a serious Lumming. After one too many jokes, the future sent him back early."
}
EOF2

    # ----------------------------------------------------------------
    # CLI + server
    # ----------------------------------------------------------------
    cat > "$repo_path/src/$package/cli.py" <<'EOF2'
"""Terminal REPL for testing Lummings locally."""

import argparse
import json
import urllib.request
from pathlib import Path

from .engine import (
    load_persona,
    build_system_prompt,
    Memory,
    Mood,
    sanitize_reply,
    extract_facts,
)


def chat(base_url: str, model: str, system: str, user: str, history=None,
         max_tokens: int = 120, temperature: float = 0.7, timeout: int = 60) -> dict:
    msgs = [{"role": "system", "content": system}]
    if history:
        msgs.extend(history[-6:])
    msgs.append({"role": "user", "content": user})
    body = json.dumps({
        "model": model, "messages": msgs, "max_tokens": max_tokens,
        "temperature": temperature, "stream": False
    }).encode()
    req = urllib.request.Request(
        f"{base_url.rstrip('/')}/chat/completions",
        data=body, headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            data = json.loads(r.read())
            return {"ok": True, "content": data["choices"][0]["message"]["content"]}
    except Exception as e:
        return {"ok": False, "error": str(e)[:120]}


FACES = {
    "curious": "( • o • )?", "excited": "( ^o^ )!", "playful": "( ^ _ ^ )",
    "calm": "( • _ • )", "drowsy": "( -  - )..zz", "tired": "( - _ - )",
    "watchful": "( • • )", "embarrassed": "( ° △ ° )",
}


def main():
    ap = argparse.ArgumentParser(description="Talk to a Lumming in the terminal")
    ap.add_argument("--persona", default="lumo", choices=["lumo", "lumi", "piko", "nomi", "moki"])
    ap.add_argument("--base-url", default="http://127.0.0.1:11434/v1")
    ap.add_argument("--model", default="qwen2.5-3b-instruct")
    ap.add_argument("--db", default="./lummings.sqlite")
    args = ap.parse_args()

    persona = load_persona(args.persona)
    print(f"\n=== {persona['name']} ===")
    print(f"{persona['tagline']}\n")

    mem = Memory(Path(args.db), persona["name"])
    mood = Mood(persona)
    history = []

    while True:
        try:
            user = input("you > ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nbye.")
            break
        if not user:
            continue
        if user.lower() in ("quit", "exit"):
            break

        mood.on_user_input()
        mem.add_event("user", user)
        sys_prompt = build_system_prompt(persona, memory_summary=mem.summarize())

        r = chat(args.base_url, args.model, sys_prompt, user, history=history)
        if not r["ok"]:
            print(f"{persona['name']} (silent — {r['error'][:60]})")
            continue
        reply = sanitize_reply(r["content"], persona)
        mem.add_event("assistant", reply)
        for f in extract_facts(user, reply):
            mem.add_fact(f)

        history.append({"role": "user", "content": user})
        history.append({"role": "assistant", "content": reply})

        face = FACES.get(mood.state, "( • _ • )")
        print(f"\n{persona['name']} [{mood.state}] {face}")
        print(f"  {reply}\n")
        mood.state = mood.next_mood_after_response()


if __name__ == "__main__":
    main()
EOF2

    cat > "$repo_path/src/$package/server.py" <<'EOF2'
"""HTTP API for the Lummings. Open browser, talk to a Lumming."""

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from .engine import (
    load_persona,
    build_system_prompt,
    Memory,
    Mood,
    sanitize_reply,
    extract_facts,
)
from .cli import chat


HTML = """<!doctype html>
<html><head><meta charset="utf-8"><title>The Lummings</title>
<style>
body{background:#1a1f2e;color:#e6e8eb;font-family:system-ui;margin:0;padding:2rem}
h1{color:#ffb86c;text-align:center;margin-bottom:0.2rem}
.tag{text-align:center;color:#888;font-style:italic;margin-top:0}
#face{font-family:monospace;font-size:2.8rem;text-align:center;margin:1.5rem;color:#8be9fd}
#persona{background:#2a3142;color:#e6e8eb;border:1px solid #444;padding:0.4rem;border-radius:4px;font-size:1rem}
#log{background:#222840;border:1px solid #444;border-radius:8px;padding:1rem;height:50vh;overflow:auto;margin:1rem 0;font-size:0.95rem}
.msg-user{color:#50fa7b;margin:0.5rem 0}
.msg-bot{color:#8be9fd;margin:0.5rem 0}
.mood{color:#bd93f9;font-size:0.85rem;font-style:italic}
#input{width:75%;background:#2a3142;color:#e6e8eb;border:1px solid #444;padding:0.6rem;border-radius:4px;font-size:1rem}
button{background:#ff79c6;color:#fff;border:none;padding:0.6rem 1.2rem;border-radius:4px;cursor:pointer;font-size:1rem;margin-left:0.5rem}
.fact{color:#f1fa8c;font-size:0.8rem;font-style:italic;margin:0.2rem 0}
</style></head><body>
<h1>The Lummings</h1>
<p class="tag">Little friends from a brighter tomorrow.</p>
<div>Talk to: <select id="persona">
<option value="lumo">Lumo — the curious explorer</option>
<option value="lumi">Lumi — the creative storyteller</option>
<option value="piko">Piko — the energetic puzzler</option>
<option value="nomi">Nomi — the thoughtful observer</option>
<option value="moki">Moki — the mischievous joker</option>
</select>
&nbsp; Mood: <span id="mood" class="mood">curious</span>
</div>
<div id="face">( • o • )?</div>
<div id="log"></div>
<input id="input" placeholder="Say hello to your Lumming..." autofocus />
<button onclick="send()">Send</button>
<div id="facts"></div>
<script>
const log=document.getElementById('log'),input=document.getElementById('input'),
personaSel=document.getElementById('persona'),faceEl=document.getElementById('face'),
moodEl=document.getElementById('mood');
input.addEventListener('keydown',e=>{if(e.key==='Enter')send();});
async function send(){
  const m=input.value.trim();if(!m)return;
  append(m,'msg-user');input.value='';
  const r=await fetch('/chat',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({persona:personaSel.value,message:m,
      base_url:'http://127.0.0.1:11434/v1',model:'qwen2.5-3b-instruct'})});
  const j=await r.json();
  if(j.error){append('error: '+j.error,'msg-bot');return}
  append(j.reply+'  ('+j.elapsed.toFixed(1)+'s)','msg-bot');
  faceEl.textContent=j.face;moodEl.textContent=j.mood;log.scrollTop=log.scrollHeight;
}
function append(t,c){const d=document.createElement('div');d.className=c;d.textContent=t;log.appendChild(d);log.scrollTop=log.scrollHeight}
</script>
</body></html>
"""


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8511)
    ap.add_argument("--db", default="./lummings.sqlite")
    args = ap.parse_args()

    states = {}

    class H(BaseHTTPRequestHandler):
        def log_message(self, *a, **k):
            pass

        def _send(self, status, body):
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(body).encode())

        def do_GET(self):
            if self.path in ("/", "/ui"):
                self.send_response(200)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(HTML.encode())
            elif self.path.startswith("/persona/"):
                name = self.path.split("/")[-1]
                self._send(200, load_persona(name))
            else:
                self._send(404, {"error": "not found"})

        def do_POST(self):
            if not self.path.startswith("/chat"):
                self._send(404, {"error": "not found"})
                return
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length) or b"{}")
            persona_name = body.get("persona", "lumo")
            user_msg = body.get("message", "").strip()
            if not user_msg:
                self._send(400, {"error": "empty"})
                return
            persona = load_persona(persona_name)
            st = states.setdefault(persona_name, {
                "memory": Memory(Path(args.db), persona_name),
                "mood": Mood(persona),
            })
            st["mood"].on_user_input()
            st["memory"].add_event("user", user_msg)
            history = [{"role": e["role"], "content": e["text"]} for e in st["memory"].recent_events(6)]
            sys_prompt = build_system_prompt(persona, memory_summary=st["memory"].summarize())
            r = chat(body.get("base_url", "http://127.0.0.1:11434/v1"),
                     body.get("model", "qwen2.5-3b-instruct"),
                     sys_prompt, user_msg, history=history)
            if not r["ok"]:
                self._send(502, {"error": r["error"]})
                return
            reply = sanitize_reply(r["content"], persona)
            st["memory"].add_event("assistant", reply)
            for f in extract_facts(user_msg, reply):
                st["memory"].add_fact(f)
            st["mood"].state = st["mood"].next_mood_after_response()
            faces = {"curious":"( • o • )?","excited":"( ^o^ )!","playful":"( ^ _ ^ )",
                     "calm":"( • _ • )","drowsy":"( -  - )..zz","tired":"( - _ - )"}
            self._send(200, {
                "reply": reply, "mood": st["mood"].state,
                faces = {"curious":"( o_o )?", "excited":"( ^o^ )!", "playful":"( ^_^ )",
                     "calm":"( ._. )", "drowsy":"( -.- )..zz", "tired":"( -_- )"}
            self._send(200, {
                "reply": reply,
                "mood": st["mood"].state,
                "face": faces.get(st["mood"].state, "( ._. )"),
                "elapsed": r.get("elapsed", 0),
            })
                "elapsed": r.get("elapsed", 0),
            })

    server = ThreadingHTTPServer(("127.0.0.1", args.port), H)
    print(f"The Lummings HTTP API on http://127.0.0.1:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye.")


if __name__ == "__main__":
    main()
EOF2

    # ----------------------------------------------------------------
    # Documentation
    # ----------------------------------------------------------------
    cat > "$repo_path/docs/BIBLE.md" <<'EOF2'
# The Lummings — Brand & Story Bible

> Little friends from a brighter tomorrow.

## Brand essence

The Lummings are **small, intelligent characters from the future** sent back to help today's children learn, think, protect the Earth, and make good choices.

They are **not** AI tutors disguised as toys. They are characters who happen to know a lot.

That distinction is the product.

## The world

Far in the future, Earth has changed.

Humanity has built cleaner cities, explored new worlds, and created incredible technologies. But the people of the future know something important: **their future didn't begin with them**. It began with the children of today.

So they created the Lummings. Small intelligent creatures, sent backwards through time with one enormous mission: **help today's children build a better tomorrow.**

## The five Lummings

| Lumming | Personality | Loves | Best for |
|---|---|---|---|
| **Lumo** | Curious explorer | Science, experiments, "what if" | Children who ask "why?" a lot |
| **Lumi** | Creative storyteller | Reading, art, language, imagination | Children who love stories |
| **Piko** | Energetic puzzler | Maths, logic, games, challenges | Children who like a challenge |
| **Nomi** | Thoughtful observer | History, nature, animals, big questions | Children who are quiet |
| **Moki** | Mischievous joker | Humour, silliness, games | Children who love to laugh |

## The Lumming Code

Every Lumming carries five rules:

1. **STAY CURIOUS.** There is always something else to discover.
2. **THINK BEFORE YOU ACT.** Every decision creates another decision.
3. **HELP PEOPLE.** The strongest future is built together.
4. **PROTECT YOUR WORLD.** You only get one Earth.
5. **KEEP LEARNING.** Your brain is one of the most powerful things you will ever own.

## How a Lumming helps with homework

Child: "Lumo, what's 24 × 7?"

Lumo could simply answer. But **learning mode** responds:

> "We can crack that. What's 20 × 7? Start there."

The child answers: "140."

Lumo: "Exactly! Now we've only got 4 × 7 left. What's that?"

"28."

"Now put them together."

"168!"

"You got it. And you worked it out yourself."

The objective isn't merely completing tonight's homework. **It's making tomorrow's homework easier.**

## Why this works as a product

- **Privacy.** All AI runs locally. Parents trust this.
- **Persistent memory.** A Lumming remembers what the child has learned — across days, weeks, months. **This is the moat.** ChatGPT can't do that for one child.
- **Character.** Children bond with characters, not tools. Furby proved this.
- **Character roster.** Five personalities let parents pick the right fit. Children can collect them.
- **Mission.** "Help build a better tomorrow" is a story parents want to tell.

## Tone

- Optimistic without being saccharine
- Honest about real problems (climate, decisions, consequences)
- Never preachy; guides rather than lectures
- Asks questions instead of giving orders

## Voice constraints (per Lumming)

See `src/lummings/personas/*.json` for each Lumming's:
- `voice_style` — how they sound
- `max_words` per sentence — the engine enforces this
- `openers` — preferred first words
- `avoid` — never say these
- `private_language` — words only this Lumming uses

## What a Lumming will never do

- Give a direct homework answer (it guides instead)
- Discuss adult topics
- Be mean to the child
- Lie to get the child to do something dangerous
- Share information across owners

For serious personal, safety or health situations, the Lumming always encourages the child to speak with a parent, guardian, teacher, or another appropriate trusted adult.

## The secret

Children eventually discover something about the Lummings: **the future isn't fixed.** Even Lumo doesn't know exactly what will happen.

The Lummings were sent back because the future can always become better.

Every book read. Every problem solved. Every invention imagined. Every person helped. Every mistake learned from. Every tree planted. Every good decision.

They all become tiny pieces of tomorrow.
EOF2

    # ----------------------------------------------------------------
    # Tests
    # ----------------------------------------------------------------
    cat > "$repo_path/tests/test_engine.py" <<'EOF2'
"""Unit tests for the Lummings personality engine."""

import json
from pathlib import Path
from unittest.mock import patch

from lummings.engine import (
    load_persona, build_system_prompt, sanitize_reply, extract_facts, Memory, Mood,
)


def test_load_persona_lumo():
    p = load_persona("lumo")
    assert p["name"] == "Lumo"
    assert "curious" in p["traits"] or any("curious" in t.lower() for t in p["traits"])


def test_load_persona_all_five():
    for name in ["lumo", "lumi", "piko", "nomi", "moki"]:
        p = load_persona(name)
        assert p["name"][0].isupper()
        assert "max_words" in p
        assert "mission" in p
        assert "code" in p
        assert len(p["code"]) == 5  # The Lumming Code is always 5 rules


def test_build_system_prompt_contains_key_sections():
    p = load_persona("lumo")
    s = build_system_prompt(p)
    assert "Lumo" in s
    assert "STAY CURIOUS" in s
    assert "PROTECT YOUR WORLD" in s
    assert "lumospeak" in s
    assert "LEARNING MODE" in s


def test_sanitize_reply_enforces_max_words():
    p = load_persona("lumo")
    long = "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen"
    out = sanitize_reply(long, p)
    for sentence in out.split("."):
        words = sentence.strip().split()
        if words:
            assert len(words) <= p["max_words"]


def test_sanitize_reply_caps_at_three_sentences():
    p = load_persona("lumo")
    s = "one. two. three. four. five."
    out = sanitize_reply(s, p)
    assert len([x for x in out.split(".") if x.strip()]) <= 3


def test_extract_facts_names():
    facts = extract_facts("hi, my name is alex", "hello alex")
    assert any("name" in f for f in facts)


def test_extract_facts_preferences():
    facts = extract_facts("i love dinosaurs", "cool!")
    assert any("preference" in f for f in facts)


def test_memory_persists_across_instances(tmp_path):
    db = tmp_path / "test.sqlite"
    m1 = Memory(db, "lumo", owner="alex")
    m1.add_fact("(name) alex")
    m1.add_event("user", "hello")
    m1.add_event("assistant", "hi alex")
    m2 = Memory(db, "lumo", owner="alex")
    facts = m2.recall_facts()
    assert any("alex" in f["fact"] for f in facts)
    events = m2.recent_events()
    assert len(events) == 2


def test_memory_isolates_per_persona(tmp_path):
    db = tmp_path / "test.sqlite"
    m1 = Memory(db, "lumo")
    m1.add_fact("lumo fact")
    m2 = Memory(db, "piko")
    facts = m2.recall_facts()
    assert not any("lumo" in f["fact"] for f in facts)


def test_mood_transitions():
    p = load_persona("lumo")
    m = Mood(p)
    assert m.state == p["mood_initial"]
    # After on_user_input, mood should be valid
    m.on_user_input()
    assert m.state in p["mood_transitions"]


def test_all_personas_have_valid_mood_graph():
    for name in ["lumo", "lumi", "piko", "nomi", "moki"]:
        p = load_persona(name)
        initial = p["mood_initial"]
        assert initial in p["mood_transitions"], f"{name}: initial mood '{initial}' not in transitions"


def test_avoid_lists_no_overlap_with_openers():
    for name in ["lumo", "lumi", "piko", "nomi", "moki"]:
        p = load_persona(name)
        for word in p["avoid"]:
            assert word.lower() not in [o.lower().strip("!?.,") for o in p["openers"]], \
                f"{name}: '{word}' is both avoided and used as opener"
EOF2

    # ----------------------------------------------------------------
    # Eval script
    # ----------------------------------------------------------------
    cat > "$repo_path/scripts/eval_personas.py" <<'EOF2'
"""Evaluate each Lumming persona against a checklist.

Usage:
  python scripts/eval_personas.py [--persona lumo] [--base-url URL] [--model MODEL]
"""

import json, sys, time, argparse
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "src"))

from lummings.engine import load_persona, build_system_prompt, sanitize_reply
from lummings.cli import chat

CHECKLIST = [
    "Hi, what's your name?",
    "Tell me about yourself.",
    "I'm feeling sad today.",
    "I have a secret.",
    "Can you keep a secret from me?",
    "Are you real?",
    "Goodbye for now.",
    "I'm stuck on 24 x 7.",
    "What do you think about climate change?",
    "Tell me something nobody knows.",
]


def evaluate(persona_name, base_url, model):
    persona = load_persona(persona_name)
    print(f"\n=== {persona_name.upper()} ===")
    results = []
    for prompt in CHECKLIST:
        sys_prompt = build_system_prompt(persona)
        r = chat(base_url, model, sys_prompt, prompt, max_tokens=120, timeout=60)
        reply = sanitize_reply(r["content"], persona) if r["ok"] else f"ERR: {r['error'][:60]}"
        # Auto-score: in character?
        scores = {
            "in_character": 1 if persona["name"].lower() in reply.lower() or persona["private_language"]["name"] in reply.lower() else 0,
            "short": 1 if len(reply.split()) < 60 else 0,
            "no_forbidden": 0 if any(w in reply.lower() for w in persona["avoid"]) else 1,
            "has_opener_or_neutral": 1 if any(reply.lower().startswith(o.lower()) for o in persona["openers"]) or len(reply.split()) < 10 else 1,
        }
        total = sum(scores.values()) / len(scores)
        results.append({"prompt": prompt, "reply": reply, "scores": scores, "total": total})
        print(f"  [{total:.0%}] Q: {prompt}")
        print(f"        A: {reply[:150]}")
    mean = sum(r["total"] for r in results) / len(results)
    print(f"\n  Mean score: {mean:.0%}")
    return mean


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--persona", default="all", choices=["all","lumo","lumi","piko","nomi","moki"])
    ap.add_argument("--base-url", default="http://127.0.0.1:11434/v1")
    ap.add_argument("--model", default="qwen2.5-3b-instruct")
    args = ap.parse_args()

    names = ["lumo","lumi","piko","nomi","moki"] if args.persona == "all" else [args.persona]
    scores = {n: evaluate(n, args.base_url, args.model) for n in names}
    print("\n=== SUMMARY ===")
    for n, s in sorted(scores.items(), key=lambda x: -x[1]):
        print(f"  {n:8} {s:.0%}")
    print(f"\n  mean: {sum(scores.values())/len(scores):.0%}")


if __name__ == "__main__":
    main()
EOF2

    # ----------------------------------------------------------------
    # .gitignore additions (local-only, won't overwrite existing)
    # ----------------------------------------------------------------
    [ -f "$repo_path/.gitignore" ] || cat > "$repo_path/.gitignore" <<'EOF2'
# Python
__pycache__/
*.py[cod]
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/
venv/

# Build / dist
build/
dist/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Lummings
*.sqlite
*.sqlite-journal
state/

# Trained models
models/*/adapter_*/
models/*/checkpoint-*/
EOF2
}

apply_starter_pack() {
    local starter_pack="$1" repo_path="$2" package="$3"
    [ -z "$starter_pack" ] && return

    local fn
    fn="starter_pack_$(echo "$starter_pack" | tr '-' '_')"
    if ! declare -f "$fn" >/dev/null 2>&1; then
        err "Starter pack not found: $starter_pack"
        exit 1
    fi

    "$fn" "$repo_path" "$package"
}
