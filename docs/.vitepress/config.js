import { defineConfig } from 'vitepress'
import fs from 'node:fs'
import path from 'node:path'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "AndroidToolBox",
  description: "AndroidToolBox Vitepress webpage",
  locales: {
    root: {
      label: "简体中文",
      lang: "zh-CN",
      link: "/",
      themeConfig: {
        nav: [
          { text: '主页', link: '/' },
          { text: '示例', link: '/examples' }
        ],

        sidebar: [
          {
            text: '示例',
            items: [
              { text: '功能示例', link: '/examples' },
              { text: '插件开发示例', link: '/api-examples' }
            ]
          }
        ],

        socialLinks: [
          { icon: 'github', link: 'https://github.com/vuejs/vitepress' }
        ]
      }
    },
    en: {
      label: "English",
      lang: "en-US",
      link: "/en/",
      themeConfig: {
        nav: [
          { text: 'Home', link: '/' },
          { text: 'Examples', link: '/examples' }
        ],

        sidebar: [
          {
            text: 'Examples',
            items: [
              { text: 'Feature Examples', link: '/examples' },
              { text: 'Plugin API Examples', link: '/api-examples' }
            ]
          }
        ],

        socialLinks: [
          { icon: 'github', link: 'https://github.com/AllToolBox-SC/AndroidToolBox' }
        ]
      }      
    }
  },
  markdown: {
    languages: [
      {
        id: 'filetree',
        scopeName: 'source.filetree',
        grammar: JSON.parse(
          fs.readFileSync(
            path.resolve(path.join(__dirname, 'languages'), 'filetree.tmLanguage.json'),
            'utf-8'
          )
        ),
        aliases: ['tree']
      }
    ]
  }
  
})
