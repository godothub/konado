import { splitCodeAndComment, tokenizeLine } from "./language";

export function formatSource(source: string, indent: string): string {
	const lines = source.split(/\r?\n/u);
	let depth = 0;
	let inBranch = false;
	let inScreenText = false;

	const formatted = lines.map((line) => {
		const { code, comment } = splitCodeAndComment(line);
		const content = code.trim();
		const commentText = comment.trimEnd();
		if (content.length === 0) {
			return commentText.length > 0
				? `${indent.repeat(depth)}${commentText.trimStart()}`
				: "";
		}

		const tokens = tokenizeLine(line);
		const root = tokens[0]?.text.replace(/:$/u, "") ?? "";
		if (root === "branch") {
			inBranch = true;
			depth = 0;
		} else if (
			root === "else" ||
			root === "endif" ||
			tokens[0]?.text === "}"
		) {
			depth = Math.max(inBranch ? 1 : 0, depth - 1);
		}

		const normalized = normalizeCode(content, tokens);
		const suffix =
			commentText.length > 0 ? `  ${commentText.trimStart()}` : "";
		const result = `${indent.repeat(depth)}${normalized}${suffix}`;

		if (root === "branch") {
			depth = 1;
		} else if (root === "if" || root === "else") {
			depth += 1;
		} else if (root === "screentext" && content.endsWith("{")) {
			inScreenText = true;
			depth += 1;
		} else if (tokens[0]?.text === "}") {
			inScreenText = false;
		}

		if (!inScreenText && root === "end" && inBranch) {
			depth = 1;
		}
		return result;
	});

	return formatted.join("\n");
}

function normalizeCode(
	content: string,
	tokens: ReturnType<typeof tokenizeLine>,
): string {
	if (tokens.length === 0) {
		return content;
	}
	if (tokens[0]?.quoted || tokens[0]?.text === "screentext") {
		return content;
	}
	if (tokens[0]?.text === "if") {
		const colon = content.endsWith(":") ? ":" : "";
		return `${tokens
			.map((token) => formatToken(token))
			.join(" ")
			.replace(/:$/u, "")}${colon}`;
	}
	if (tokens[0]?.text === "else") {
		return "else:";
	}
	if (tokens[0]?.text === "choice" && tokens.length >= 4) {
		const head = `${formatToken(tokens[0]!)} ${formatToken(tokens[1]!)} -> ${formatToken(tokens[3]!)}`;
		const filters = tokens
			.slice(4)
			.map((token) => formatToken(token))
			.join(" ");
		return filters.length > 0 ? `${head} ${filters}` : head;
	}
	return tokens.map((token) => formatToken(token)).join(" ");
}

function formatToken(
	token: NonNullable<ReturnType<typeof tokenizeLine>[number]>,
): string {
	if (!token.quoted) {
		return token.text;
	}
	return `"${token.text}"`;
}
