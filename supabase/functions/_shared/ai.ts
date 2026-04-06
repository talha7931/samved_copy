import { env } from "./env.ts";

export async function callAiService<TResponse>(
  path: string,
  payload: Record<string, unknown>,
): Promise<TResponse> {
  const response = await fetch(`${env.aiServiceUrl}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-SSR-Secret": env.aiServiceSecret,
    },
    body: JSON.stringify(payload),
  });

  const contentType = response.headers.get("content-type") ?? "";
  const body = contentType.includes("application/json")
    ? await response.json()
    : await response.text();

  if (!response.ok) {
    throw new Error(
      `AI service ${path} failed with ${response.status}: ${
        typeof body === "string" ? body : JSON.stringify(body)
      }`,
    );
  }

  return body as TResponse;
}

