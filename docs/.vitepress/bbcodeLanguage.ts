import type { MarkdownOptions } from 'vitepress'

type MarkdownLanguage = NonNullable<MarkdownOptions['languages']>[number]

export const bbcodeLanguage: MarkdownLanguage = {
  name: 'bbcode',
  displayName: 'BBCode',
  scopeName: 'text.bbcode',
  aliases: ['bb-code'],
  repository: {},
  patterns: [
    {
      begin: '(\\[/?)([A-Za-z][A-Za-z0-9_:-]*)',
      beginCaptures: {
        1: { name: 'punctuation.definition.tag.begin.bbcode' },
        2: { name: 'entity.name.tag.bbcode' }
      },
      end: '(\\])',
      endCaptures: {
        1: { name: 'punctuation.definition.tag.end.bbcode' }
      },
      name: 'meta.tag.bbcode',
      patterns: [
        {
          captures: {
            1: { name: 'keyword.operator.assignment.bbcode' },
            2: { name: 'string.unquoted.bbcode' }
          },
          match: '(=)([^\\]\\s]+)'
        },
        {
          captures: {
            1: { name: 'entity.other.attribute-name.bbcode' },
            2: { name: 'keyword.operator.assignment.bbcode' },
            3: { name: 'string.quoted.double.bbcode' },
            4: { name: 'string.quoted.single.bbcode' },
            5: { name: 'string.unquoted.bbcode' }
          },
          match: '\\b([A-Za-z][A-Za-z0-9_:-]*)(=)(?:"([^"]*)"|\\\'([^\\\']*)\\\'|([^\\]\\s]+))'
        },
        {
          match: '\\b[A-Za-z][A-Za-z0-9_:-]*\\b',
          name: 'entity.other.attribute-name.bbcode'
        }
      ]
    }
  ]
}
