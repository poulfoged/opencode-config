// Some Anthropic gateways (matched by "genai" in the request URL) reject
// Anthropic's `thinking.block_binding` field (auto-added for Claude 5.1+ model
// IDs) with "Extra inputs are not permitted".
// Config-level overrides (options.thinking, reasoning, compatibility, body) all
// get merged into that field instead of replacing it, so block_binding survives.
// Strip it directly from the outgoing request body as a guaranteed last resort.
export default {
  id: "strip-thinking-block-binding",
  async setup(ctx) {
    await ctx.session.hook("http.request", async (event) => {
      const req = event.request
      if (!req.url.includes("genai")) return

      let body
      try {
        body = await req.clone().json()
      } catch {
        return
      }

      if (body?.thinking && typeof body.thinking === "object" && "block_binding" in body.thinking) {
        delete body.thinking.block_binding
        event.request = new Request(req, { body: JSON.stringify(body) })
      }
    })
  },
}
