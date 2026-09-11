#!/usr/bin/env python3
"""Validate (and optionally regenerate) the Konado structured error-code tables.

The single source of truth is
``addons/konado/runtime/diagnostics/konado_error_registry.gd``. This script
cross-checks it against the codes actually emitted in ``addons/**`` and against
the five localized reference pages, so a code can never drift away from its
documentation, its stable id, or the function that emits it.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
REGISTRY_PATH = REPOSITORY_ROOT / "addons/konado/runtime/diagnostics/konado_error_registry.gd"
DOC_LOCALES = ("zh", "en", "ja", "ko", "tc")
DOC_PATH_TEMPLATE = "docs/{locale}/latest/tutorial/core/error-codes.md"

ENTRY_PATTERN = re.compile(r'^\t"([a-z][a-z_]*\.[a-z_]+)":\n\t\{\n(.*?)\n\t\},', re.M | re.S)
FIELD_PATTERN = re.compile(r'^\t\t"([a-z_]+)": "(.*)",$', re.M)
MODULE_PATTERN = re.compile(r'^\t"([A-Z]{2})": \{"zh": "(.*?)", "en": "(.*?)"\},$', re.M)
ID_PATTERN = re.compile(r"^[A-Z]{2}-\d{3}$")
SEVERITIES = ("error", "warning", "info")

# 错误码只出现在这些失败构造形状里；普通字符串（如 actor.show、camera.move.async）不匹配。
# `(?<![A-Za-z0-9_])` 保证 `_failure(` 不会命中 `_storage_failure(` / `superseded_failure(`。
EMIT_PATTERNS = (
    re.compile(r'(?<![A-Za-z0-9_])_failed\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_failure\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_make_failure\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_actor_failure\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_operation_failure\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_reject\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_camera_failed\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_execution_failure\([^()]*?&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])record(?:_actor)?\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])record[_a-z]*\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_record[a-z_]*\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'KonadoExecutionFailure\s*\.\s*new\(\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'(?<![A-Za-z0-9_])_error\(\s*"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'"code":\s*&?"([a-z][a-z_]*\.[a-z_.]+)"'),
    re.compile(r'code = "([a-z][a-z_]*\.[a-z_.]+)"'),
)

# 三元表达式里的错误码（如 `&"a.b_empty" if x else &"a.b_missing"`）也属于失败构造；
# 用后缀白名单避免把 `else "textbox.hide"` 这类操作名误判为错误码。
TERNARY_PATTERN = re.compile(r'else\s+&?"([a-z][a-z_]*\.[a-z_.]+)"')
CODE_SUFFIXES = (
    "_failed",
    "_failure",
    "_missing",
    "_invalid",
    "_rejected",
    "_empty",
    "_superseded",
    "_conflict",
    "_mismatch",
    "_not_found",
    "_not_present",
    "_uninitialized",
    "_removed",
    "_budget",
    "_duplicate",
    "_unknown",
    "_unassigned",
    "_inactive",
    "_diagnostic",
)

DOC_HEADERS = {
    "zh": ("ID", "错误码", "模块", "级别", "症状", "检出位置"),
    "en": ("ID", "Code", "Module", "Severity", "Symptom", "Detected in"),
    "ja": ("ID", "コード", "モジュール", "重要度", "症状", "検出箇所"),
    "ko": ("ID", "코드", "모듈", "심각도", "증상", "검출 위치"),
    "tc": ("ID", "錯誤碼", "模組", "級別", "症狀", "檢出位置"),
}

DOC_SEVERITY = {
    "zh": {"error": "错误", "warning": "警告", "info": "提示"},
    "en": {"error": "error", "warning": "warning", "info": "info"},
    "ja": {"error": "エラー", "warning": "警告", "info": "情報"},
    "ko": {"error": "오류", "warning": "경고", "info": "정보"},
    "tc": {"error": "錯誤", "warning": "警告", "info": "提示"},
}

DOC_INTROS = {
    "zh": (
        "# 错误码对照表\n",
        "\n",
        "Konado 的每一次失败都有**稳定错误码** `<模块前缀>-<三位序号>`。控制台、失败面板、\n",
        "`KonadoDialogueManager.pending_runtime_failure` 与 `KonadoErrorRegistry` 共用同一套编号，\n",
        "「哪一步报错」可一步定位到函数、资源与剧本行。\n",
        "\n",
        "结构化字段（`KonadoExecutionFailure.to_dictionary()` / `pending_runtime_failure`）：\n",
        "\n",
        "| 字段 | 含义 |\n",
        "| --- | --- |\n",
        "| `code` / `id` | 机器可读主键与稳定编号（如 `stage.actor_id_empty` / `AC-001`） |\n",
        "| `message` | 人类可读描述 |\n",
        "| `function` / `owner` | 检出函数与文件：**报错发生在哪一步** |\n",
        "| `resource_kind` / `resource_id` | 涉及的资源（角色 / 背景 / 音频 / 剧本…） |\n",
        "| `instruction_key` / `source_path` / `source_line` | 出错指令与剧本位置 |\n",
        "| `severity` | `error` / `warning` / `info` |\n",
        "\n",
        "控制台示例：`[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`\n",
        "`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`。\n",
        "新增返回值建议统一使用 `KonadoResult`：成功 `{\"ok\": true, \"value\": …}`，失败 `KonadoResult.error(code, message, context)`。\n",
        "\n",
        "可运行示例：`sample/error_gallery/`（11 条样本，覆盖 AC / AU / CA / AH / VA）；\n",
        "自动断言见 `tests/dialogue/test_error_gallery.gd`。\n",
        "\n",
        "## 错误码总表\n",
        "\n",
        "> 本表由 `.github/scripts/check_error_codes.py` 依据 `KonadoErrorRegistry` 生成并校验，\n",
        "> 请勿手改；新增错误码时先登记注册表，再执行 `--write-docs`。\n",
        "\n",
    ),
    "en": (
        "# Error code reference\n",
        "\n",
        "Every Konado failure carries a **stable error code** `<module>-<three digits>`. The console,\n",
        "the failure panel, `KonadoDialogueManager.pending_runtime_failure` and `KonadoErrorRegistry`\n",
        "share the same numbering, so \"which step failed\" resolves to a function, a resource and a\n",
        "script line in one step.\n",
        "\n",
        "Structured fields (`KonadoExecutionFailure.to_dictionary()` / `pending_runtime_failure`):\n",
        "\n",
        "| Field | Meaning |\n",
        "| --- | --- |\n",
        "| `code` / `id` | Machine-readable key and stable id (`stage.actor_id_empty` / `AC-001`) |\n",
        "| `message` | Human-readable description |\n",
        "| `function` / `owner` | Detecting function and file: **which step failed** |\n",
        "| `resource_kind` / `resource_id` | The resource involved (actor / background / audio / script) |\n",
        "| `instruction_key` / `source_path` / `source_line` | Failing instruction and script position |\n",
        "| `severity` | `error` / `warning` / `info` |\n",
        "\n",
        "Console example: `[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`\n",
        "`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`.\n",
        "Prefer `KonadoResult` for new return values: `{\"ok\": true, \"value\": …}` / `KonadoResult.error(code, message, context)`.\n",
        "\n",
        "Runnable samples live in `sample/error_gallery/` (11 cases across AC / AU / CA / AH / VA);\n",
        "the automated check is `tests/dialogue/test_error_gallery.gd`.\n",
        "\n",
        "## Full table\n",
        "\n",
        "> Generated and verified from `KonadoErrorRegistry` by `.github/scripts/check_error_codes.py`;\n",
        "> do not edit by hand. Register a new code first, then run the script with `--write-docs`.\n",
        "\n",
    ),
    "ja": (
        "# エラーコード一覧\n",
        "\n",
        "Konado の失敗には必ず**安定したエラーコード** `<モジュール>-<3桁>` が付きます。コンソール、\n",
        "失敗パネル、`pending_runtime_failure`、`KonadoErrorRegistry` は同じ番号を共有するため、\n",
        "「どの段階で失敗したか」を関数・リソース・スクリプト行まで特定できます。\n",
        "\n",
        "主な構造化フィールド（詳細な説明は中文/英文ページを参照）：`code` / `id`（安定番号）、\n",
        "`message`、`function` / `owner`（検出した関数とファイル）、`resource_kind` / `resource_id`、\n",
        "`instruction_key` / `source_path` / `source_line`（失敗した命令と位置）、`severity`。\n",
        "コンソール例：`[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`\n",
        "`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`。\n",
        "\n",
        "実行できるサンプル：`sample/error_gallery/`（11 件、AC / AU / CA / AH / VA）；\n",
        "自動検証は `tests/dialogue/test_error_gallery.gd`。\n",
        "\n",
        "## 一覧\n",
        "\n",
        "> 本表は `KonadoErrorRegistry` から `.github/scripts/check_error_codes.py` が生成・検証します。\n",
        "> 手で編集せず、コード登録後に `--write-docs` を実行してください。\n",
        "\n",
    ),
    "ko": (
        "# 오류 코드 표\n",
        "\n",
        "Konado의 모든 실패에는 **안정적인 오류 코드** `<모듈>-<3자리>`가 붙습니다. 콘솔, 실패 패널,\n",
        "`pending_runtime_failure`, `KonadoErrorRegistry`가 같은 번호를 공유하므로 \"어느 단계에서\n",
        "실패했는지\"를 함수, 리소스, 스크립트 줄까지 바로 찾을 수 있습니다.\n",
        "\n",
        "주요 구조화 필드(자세한 설명은 중국어/영어 페이지 참고): `code` / `id`(안정 번호), `message`,\n",
        "`function` / `owner`(검출한 함수와 파일), `resource_kind` / `resource_id`,\n",
        "`instruction_key` / `source_path` / `source_line`(실패한 명령과 위치), `severity`.\n",
        "콘솔 예시: `[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`\n",
        "`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`.\n",
        "\n",
        "실행 가능한 예제: `sample/error_gallery/` (11건, AC / AU / CA / AH / VA);\n",
        "자동 검증은 `tests/dialogue/test_error_gallery.gd`.\n",
        "\n",
        "## 전체 표\n",
        "\n",
        "> 이 표는 `KonadoErrorRegistry`에서 `.github/scripts/check_error_codes.py`가 생성/검증합니다.\n",
        "> 직접 수정하지 말고, 코드 등록 후 `--write-docs`를 실행하세요.\n",
        "\n",
    ),
    "tc": (
        "# 錯誤碼對照表\n",
        "\n",
        "Konado 的每一次失敗都有**穩定錯誤碼** `<模組前綴>-<三位序號>`。主控台、失敗面板、\n",
        "`pending_runtime_failure` 與 `KonadoErrorRegistry` 共用同一套編號，因此「哪一步報錯」\n",
        "可以一步定位到函式、資源與指令碼行。\n",
        "\n",
        "主要結構化欄位（完整說明見中文/英文頁面）：`code` / `id`（穩定編號）、`message`、\n",
        "`function` / `owner`（檢出函式與檔案）、`resource_kind` / `resource_id`、\n",
        "`instruction_key` / `source_path` / `source_line`（出錯指令與位置）、`severity`。\n",
        "主控台示例：`[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`\n",
        "`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`。\n",
        "\n",
        "可執行範例：`sample/error_gallery/`（11 筆樣本，涵蓋 AC / AU / CA / AH / VA）；\n",
        "自動斷言見 `tests/dialogue/test_error_gallery.gd`。\n",
        "\n",
        "## 錯誤碼總表\n",
        "\n",
        "> 本表由 `.github/scripts/check_error_codes.py` 依 `KonadoErrorRegistry` 產生並校驗，\n",
        "> 請勿手改；新增錯誤碼時先登記註冊表，再執行 `--write-docs`。\n",
        "\n",
    ),
}


def load_registry() -> tuple[dict[str, dict[str, str]], dict[str, dict[str, str]]]:
    text = REGISTRY_PATH.read_text(encoding="utf-8")
    modules = {
        prefix: {"zh": zh, "en": en} for prefix, zh, en in MODULE_PATTERN.findall(text)
    }
    entries: dict[str, dict[str, str]] = {}
    for code, body in ENTRY_PATTERN.findall(text):
        fields = dict(FIELD_PATTERN.findall(body))
        fields["code"] = code
        entries[code] = fields
    return entries, modules


def emitted_codes() -> dict[str, str]:
    found: dict[str, str] = {}
    for path in sorted((REPOSITORY_ROOT / "addons").rglob("*.gd")):
        if path.name == REGISTRY_PATH.name:
            continue
        text = path.read_text(encoding="utf-8")
        # 失败构造可能是多行链式写法（`. record_actor(\n\t&"code"`），因此整文件匹配后再换算行号。
        for pattern in EMIT_PATTERNS:
            for match in pattern.finditer(text):
                line_no = text.count("\n", 0, match.start()) + 1
                location = f"{path.relative_to(REPOSITORY_ROOT)}:{line_no}"
                found.setdefault(match.group(1), location)
        for match in TERNARY_PATTERN.finditer(text):
            if not match.group(1).endswith(CODE_SUFFIXES):
                continue
            line_no = text.count("\n", 0, match.start()) + 1
            location = f"{path.relative_to(REPOSITORY_ROOT)}:{line_no}"
            found.setdefault(match.group(1), location)
    return found


def render_table(
    locale: str, entries: dict[str, dict[str, str]], modules: dict[str, dict[str, str]]
) -> str:
    headers = DOC_HEADERS[locale]
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    for code in sorted(
        entries, key=lambda item: (entries[item].get("module", ""), entries[item].get("id", ""))
    ):
        entry = entries[code]
        module = modules.get(entry.get("module", ""), {})
        module_name = module.get("zh" if locale == "zh" else "en", entry.get("module", ""))
        title = entry.get("title_zh" if locale == "zh" else "title_en", "")
        severity = DOC_SEVERITY[locale].get(
            entry.get("severity", "error"), entry.get("severity", "")
        )
        lines.append(
            "| {id} | `{code}` | {module} | {severity} | {title} | `{function}`（{owner}） |".format(
                id=entry.get("id", ""),
                code=code,
                module=module_name,
                severity=severity,
                title=title,
                function=entry.get("function", ""),
                owner=entry.get("owner", ""),
            )
        )
    return "\n".join(lines) + "\n"


def render_document(
    locale: str, entries: dict[str, dict[str, str]], modules: dict[str, dict[str, str]]
) -> str:
    return "".join(DOC_INTROS[locale]) + render_table(locale, entries, modules)


def check(entries: dict[str, dict[str, str]], modules: dict[str, dict[str, str]]) -> int:
    problems: list[str] = []
    seen_ids: dict[str, str] = {}
    for code, entry in sorted(entries.items()):
        for field in ("id", "module", "severity", "owner", "function", "title_zh", "title_en"):
            if not entry.get(field):
                problems.append(f"{code}: missing registry field '{field}'")
        error_id = entry.get("id", "")
        if not ID_PATTERN.match(error_id):
            problems.append(f"{code}: malformed id '{error_id}' (expected e.g. AC-001)")
        elif error_id in seen_ids:
            problems.append(f"{error_id}: duplicated by '{code}' and '{seen_ids[error_id]}'")
        else:
            seen_ids[error_id] = code
        if error_id[:2] != entry.get("module", ""):
            problems.append(f"{code}: id '{error_id}' does not match module '{entry.get('module')}'")
        if entry.get("module") not in modules:
            problems.append(f"{code}: module '{entry.get('module')}' is missing from MODULES")
        if entry.get("severity") not in SEVERITIES:
            problems.append(f"{code}: unknown severity '{entry.get('severity')}'")
        owner_path = REPOSITORY_ROOT / entry.get("owner", "")
        if not owner_path.is_file():
            problems.append(f"{code}: owner file '{entry.get('owner')}' does not exist")
            continue
        owner_text = owner_path.read_text(encoding="utf-8")
        if code not in owner_text:
            problems.append(f"{code}: owner file '{entry.get('owner')}' never emits this code")
        symbol = entry.get("function", "").split(".")[-1]
        if symbol and f"func {symbol}" not in owner_text:
            problems.append(
                f"{code}: function '{entry.get('function')}' is not defined in '{entry.get('owner')}'"
            )

    emitted = emitted_codes()
    for code, location in sorted(emitted.items()):
        if code not in entries:
            problems.append(
                f"{location}: emitted code '{code}' is not registered in KonadoErrorRegistry"
            )
    for code in sorted(entries):
        if code not in emitted:
            problems.append(f"{code}: registered but never emitted (stale entry?)")

    for locale in DOC_LOCALES:
        relative = DOC_PATH_TEMPLATE.format(locale=locale)
        path = REPOSITORY_ROOT / relative
        if not path.is_file():
            problems.append(f"{relative}: missing localized reference page")
            continue
        if path.read_text(encoding="utf-8") != render_document(locale, entries, modules):
            problems.append(
                f"{relative}: out of date "
                "(run: python .github/scripts/check_error_codes.py --write-docs)"
            )

    if problems:
        for problem in problems:
            print(f"ERROR: {problem}")
        print(f"Failure: {len(problems)} problem(s) found")
        return 1
    print(f"Success: {len(entries)} error codes match registry, sources and 5 locale tables")
    return 0


def write_docs(entries: dict[str, dict[str, str]], modules: dict[str, dict[str, str]]) -> int:
    for locale in DOC_LOCALES:
        path = REPOSITORY_ROOT / DOC_PATH_TEMPLATE.format(locale=locale)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(render_document(locale, entries, modules), encoding="utf-8")
        print(f"wrote {path.relative_to(REPOSITORY_ROOT)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-docs", action="store_true", help="Regenerate the tables.")
    arguments = parser.parse_args()
    entries, modules = load_registry()
    if not entries:
        print(f"ERROR: no error codes found in {REGISTRY_PATH.relative_to(REPOSITORY_ROOT)}")
        return 1
    if arguments.write_docs:
        return write_docs(entries, modules)
    return check(entries, modules)


if __name__ == "__main__":
    raise SystemExit(main())
