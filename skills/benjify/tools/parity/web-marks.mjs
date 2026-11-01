// Dump every target's rect at each act.mark() of an upstream example, as
// the real playground draws it. Run with the upstream checkout's
// playwright-core (NODE_PATH or from its directory):
//
//   node web-marks.mjs <preview-url> <example> <out.json> [runs=1] [shots-dir]
//
// With shots-dir, the first run also saves a PNG of the stage the moment
// each mark lands (a page screenshot clipped to the stage, no waiting for
// motion to settle), as <shots-dir>/<mark>.png.
//
// Rects are stage pixels (the .ss-stage's own design space), relative to
// the example's `origin` element when examples.json names one. Times are
// ms from the first mark.
import { readFileSync, writeFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const [base, example, out, runsArg, shots] = process.argv.slice(2)
const config = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'examples.json'), 'utf8'))[example]
const require = createRequire(join(process.env.STAGESHOW_DIR ?? process.cwd(), 'package.json'))
const { chromium } = require('playwright-core')
const browser = await chromium.launch({ channel: 'chrome' })
const runs = []
for (let r = 0; r < Number(runsArg ?? 1); r++) {
  const page = await browser.newPage({ viewport: { width: config.width, height: 900 }, deviceScaleFactor: 2 })
  if (shots && r === 0) {
    await page.exposeFunction('__shot', async (name, clip) => {
      await page.screenshot({ path: join(shots, `${name}.png`), clip, animations: 'allow' })
    })
  }
  await page.addInitScript(({ extras, origin }) => {
    window.__marks = []
    const snap = (root, name) => {
      const box = root.getBoundingClientRect()
      const s = box.width / root.offsetWidth || 1
      const rel = (el) => {
        const b = el.getBoundingClientRect()
        return { x: (b.left - box.left) / s, y: (b.top - box.top) / s, width: b.width / s, height: b.height / s }
      }
      const rects = {}
      root.querySelectorAll('[data-target]').forEach((el) => { rects[el.dataset.target] = rel(el) })
      for (const [k, sel] of Object.entries(extras)) { const el = root.querySelector(sel); if (el) rects[k] = rel(el) }
      if (origin) {
        const o = root.querySelector(origin)
        const or = o ? rel(o) : { x: 0, y: 0 }
        for (const k of Object.keys(rects)) { rects[k] = { ...rects[k], x: rects[k].x - or.x, y: rects[k].y - or.y } }
      }
      window.__marks.push({ name, t: performance.now(), rects, scale: s })
      if (window.__shot) window.__shot(name, { x: box.left + scrollX, y: box.top + scrollY, width: box.width, height: box.height })
    }
    const watch = () => {
      const root = document.querySelector('.ss-stage')
      if (!root) return requestAnimationFrame(watch)
      new MutationObserver(() => {
        const m = root.getAttribute('data-mark')
        if (m) snap(root, m)
      }).observe(root, { attributes: true, attributeFilter: ['data-mark'] })
    }
    watch()
  }, { extras: config.extras, origin: config.origin })
  await page.goto(`${base}/?capture=${example}`)
  await page.waitForTimeout(config.seconds * 1000)
  const marks = await page.evaluate(() => window.__marks)
  const t0 = marks[0]?.t ?? 0
  runs.push(marks.map((m) => ({ name: m.name, time: (m.t - t0) / 1000, rects: m.rects, scale: m.scale })))
  await page.close()
}
await browser.close()
writeFileSync(out, JSON.stringify(runs, null, 1))
console.log(`${example}: ${runs.length} run(s), marks ${runs.map((r) => r.map((m) => m.name).join(',')).join(' | ')}`)
