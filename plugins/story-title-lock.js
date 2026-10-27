// Keeps the session title set by ~/.config/opencode/scripts/story.sh (and any
// manual rename afterwards) from being replaced by automatic title generation.
// story.sh drops a marker file per session; sessions without one are untouched.
import * as fs from "node:fs"
import * as os from "node:os"
import * as path from "node:path"

const markerDir = path.join(
  process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local", "state"),
  "opencode-story",
)

export default {
  id: "lego.story-title-lock",
  async setup(ctx) {
    await ctx.session.hook("title", async (event) => {
      if (!fs.existsSync(path.join(markerDir, event.sessionID))) return
      const session = await ctx.session.get({ sessionID: event.sessionID })
      if (session?.title) event.result = session.title
    })
  },
}
