import { defineConfig } from 'vitepress'
import { MermaidMarkdown, MermaidPlugin } from 'vitepress-plugin-mermaid'
import { fileURLToPath } from 'url'
import { dirname, resolve } from 'path'
import { genZhSidebar, genEnSidebar, genTcSidebar } from './genSidebar'

const __dirname = dirname(fileURLToPath(import.meta.url))
const docsRoot = resolve(__dirname, '..')

export default defineConfig({

  lastUpdated: true,

  markdown: {
    config(md) {
      md.use(MermaidMarkdown)
    },
  },
  vite: {
    plugins: [MermaidPlugin()],
    optimizeDeps: {
      include: ['mermaid'],
    },
    ssr: {
      noExternal: ['mermaid'],
    },
  },

  title: "Konado",
  base: "/oss/konado/",
  description: "Konado: Visual Novel Framework",
  head: [
    [
      'link',
      { rel: 'icon', href: 'https://godothub.atomgit.net/web/icon/konado/kona/icon.png' }
    ]
  ],
  themeConfig: {
    outline: [2, 3],
    logo: 'https://godothub.atomgit.net/web/icon/konado/kona/icon.png',
    search: {
      provider: 'local'
    },
    socialLinks: [
      {
        icon: 'github', link: 'https://github.com/godothub/konado'
      },
      {
        icon: {
          svg: '<svg t="1752549772860" class="icon" viewBox="0 0 1056 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="2154" width="200" height="200"><path d="M479.663158 988.429474c-90.004211-10.24-187.553684-48.505263-247.376842-96.471579-33.953684-26.947368-90.004211-88.387368-111.023158-120.724211-64.134737-99.166316-90.004211-222.046316-70.602105-333.608421 18.863158-107.250526 63.056842-191.326316 141.20421-267.856842 135.814737-133.12 353.010526-175.157895 527.090526-101.861053 57.128421 24.252632 112.101053 58.206316 134.736843 82.997895 44.193684 49.044211 28.025263 128.808421-31.258948 158.450526-25.330526 12.395789-72.218947 12.934737-90.543158 1.077895s-35.031579-44.193684-39.343158-77.069473c-2.155789-15.629474-4.850526-28.564211-5.389473-28.564211-1.077895 0-14.551579 7.545263-29.642106 16.168421-49.583158 29.103158-64.134737 33.414737-140.126315 38.265263-39.882105 2.155789-84.075789 5.928421-97.549474 8.084211-24.791579 3.233684-54.972632-1.077895-102.938947-16.168421l-25.330527-8.084211 1.077895 52.277895c0.538947 50.661053 0 53.355789-21.557895 98.088421-28.025263 58.206316-38.265263 93.237895-42.576842 144.976842-10.24 124.496842 57.667368 217.195789 186.47579 253.844211 83.536842 23.713684 221.507368 18.863158 296.421052-10.778948 71.68-28.564211 134.736842-94.854737 134.736842-142.282105 0-19.402105-24.791579-44.193684-51.738947-50.661053-11.317895-3.233684-54.433684-7.006316-95.393684-8.623158-86.770526-3.772632-147.132632-11.856842-163.84-22.635789s-25.330526-40.96-17.785263-63.59579c7.545263-23.713684 19.402105-33.953684 54.433684-46.888421 23.713684-9.162105 40.96-10.778947 109.945263-10.778947 146.593684 0 215.578947 18.324211 269.473684 72.218947 61.978947 62.517895 68.446316 157.372632 16.168421 241.448421-77.069474 123.418947-168.151579 194.021053-291.570526 225.818948-41.498947 11.317895-151.444211 18.324211-196.176842 12.934737z" fill="#D62240" p-id="2155"></path></svg>'
        }, link: 'https://atomgit.com/godothub/konado'
      },
      {
        icon:
        {
          svg: '<svg t="1752549910319" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="4388" width="200" height="200"><path d="M512 512m-512 0a512 512 0 1 0 1024 0 512 512 0 1 0-1024 0Z" fill="#FFAD16" p-id="4389"></path><path d="M500.053333 571.733333s-8.533333-25.6-8.533333-35.84v-5.12c0-58.026667 46.08-105.813333 100.693333-105.813333 27.306667 0 52.906667 5.12 71.68 25.6 13.653333-15.36 32.426667-22.186667 52.906667-23.893333-5.12-81.92-69.973333-153.6-150.186667-153.6-40.96 0-80.213333 17.066667-107.52 47.786666C431.786667 290.133333 392.533333 273.066667 351.573333 273.066667c-83.626667 0-150.186667 69.973333-150.186666 155.306667v8.533334c0 15.36 3.413333 32.426667 10.24 49.493333v1.706667c46.08 109.226667 221.866667 237.226667 230.4 242.346666 5.12 3.413333 10.24 5.12 15.36 5.12 5.12 0 11.946667-1.706667 15.36-5.12 3.413333-3.413333 39.253333-27.306667 88.746666-69.973333-27.306667-25.6-49.493333-58.026667-61.44-88.746667z m0 0" fill="#FFFFFF" p-id="4390"></path><path d="M815.786667 539.306667c0-49.493333-39.253333-88.746667-85.333334-88.746667-23.893333 0-46.08 10.24-61.44 27.306667-15.36-17.066667-37.546667-27.306667-61.44-27.306667-47.786667 0-85.333333 40.96-85.333333 88.746667v6.826666c0 8.533333 1.706667 18.773333 6.826667 29.013334v1.706666c25.6 63.146667 128 134.826667 131.413333 138.24 3.413333 1.706667 5.12 3.413333 8.533333 3.413334s6.826667-1.706667 8.533334-3.413334c3.413333-3.413333 90.453333-64.853333 124.586666-122.88 1.706667-1.706667 1.706667-3.413333 3.413334-5.12v-1.706666c1.706667-3.413333 3.413333-8.533333 5.12-11.946667 3.413333-8.533333 5.12-17.066667 5.12-25.6V546.133333v-6.826666z m0 0" fill="#FFFFFF" p-id="4391"></path></svg>'
        }, link: 'https://ifdian.net/item/52230b2860a011f083ef52540025c377'
      }
    ],
    footer: {
      message: 'Released under BSD3-Clause License.',
      copyright: 'Copyright © 2025 Konado Project. <br>All rights reserved.'
    }
  },

  locales: {

    zh: {
      label: '简体中文',
      lang: 'zh-CN',
      description: 'Konado: 视觉小说框架',
      themeConfig: {
        lastUpdatedText: '最后更新于',
        editLink: {
          pattern: 'https://github.com/godothub/konado/edit/main/docs/:path',
          text: '在线编辑此页'
        },
        outlineTitle: '本页目录',
        returnToTopLabel: '返回顶部',
        darkModeSwitchLabel: '深色模式',
        docFooter: {
          prev: '上一页',
          next: '下一页'
        },
        search: {
          provider: 'local',
          options: {
            translations: {
              button: {
                buttonText: '搜索',
                buttonAriaLabel: '搜索'
              },
              modal: {
                footer: {
                  selectText: '选择',
                  navigateText: '切换',
                  closeText: '关闭'
                }
              }
            }
          }
        },
        nav: [
          { text: 'Godot Hub', link: 'https://godothub.com' },
          { text: '查看文档', link: '/zh/tutorial/install' },
          { text: '下载插件', link: 'https://github.com/godothub/konado/releases/latest' },
          { text: '赞助我们', link: 'https://ifdian.net/item/52230b2860a011f083ef52540025c377' }
        ],
        sidebar: genZhSidebar(docsRoot)
      }
    },

    tc: {
      label: '繁體中文',
      lang: 'zh-CN',
      description: 'Konado: 視覺小說框架',
      themeConfig: {
        lastUpdatedText: '最後更新於',
        editLink: {
          pattern: 'https://github.com/godothub/konado/edit/main/docs/:path',
          text: '在線編輯此頁'
        },
        outlineTitle: '本頁目錄',
        returnToTopLabel: '返回頂部',
        darkModeSwitchLabel: '深色模式',
        docFooter: {
          prev: '上一頁',
          next: '下一頁'
        },
        search: {
          provider: 'local',
          options: {
            translations: {
              button: {
                buttonText: '搜索',
                buttonAriaLabel: '搜索'
              },
              modal: {
                footer: {
                  selectText: '選擇',
                  navigateText: '切換',
                  closeText: '關閉'
                }
              }
            }
          }
        },
        nav: [
          { text: 'Godot Hub', link: 'https://godothub.com' },
          { text: '查看文檔', link: '/tc/tutorial/install' },
          { text: '下載插件', link: 'https://github.com/godothub/konado/releases/latest' },
          { text: '贊助我們', link: 'https://ifdian.net/item/52230b2860a011f083ef52540025c377' }
        ],
        sidebar: genTcSidebar(docsRoot)
      }
    },

    en: {
      label: 'English',
      lang: 'en',
      description: 'Konado: Visual Novel Framework',
      themeConfig: {
        lastUpdatedText: 'Last updated on',
        editLink: {
          pattern: 'https://github.com/godothub/konado/edit/main/docs/:path',
          text: 'Edit this page online'
        },
        nav: [
          { text: 'Godot Hub', link: 'https://godothub.com' },
          { text: 'Documentation', link: '/en/tutorial/install' },
          { text: 'Download Plugin', link: 'https://github.com/godothub/konado/releases/latest' },
          { text: 'Sponsor Us', link: 'https://ifdian.net/item/52230b2860a011f083ef52540025c377' }
        ],
        sidebar: genEnSidebar(docsRoot)
      }
    }
  }
})
