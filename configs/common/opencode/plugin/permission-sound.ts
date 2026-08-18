import type { Plugin } from "@opencode-ai/plugin"

const SOUND = "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"

export default (async ({ $ }) => {
  return {
    "permission.ask": async () => {
      await $`paplay ${SOUND}`
    },
    event: async ({ event }) => {
      if (event.type === "question.asked") {
        await $`paplay ${SOUND}`
      }
    },
  }
}) satisfies Plugin
