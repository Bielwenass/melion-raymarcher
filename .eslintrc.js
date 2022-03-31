module.exports = {
  root: true,
  env: {
    node: true
  },
  extends: [
    // Vue plugins description below
    // https://eslint.vuejs.org/rules/
    'standard',
    'plugin:vue/recommended'
  ],
  parserOptions: {
    ecmaVersion: 2020,
    ecmaFeatures: {
      useStrict: true
    }
  },
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off',

    // Max 120 symbols per line
    'max-len': ['warn', {
      code: 120,
      ignoreStrings: true,
      ignoreComments: true,
      ignoreRegExpLiterals: true
    }],

    // Padding lines
    'padding-line-between-statements': ['error',

      // Newline after variable declarations
      {
        blankLine: 'always', prev: 'const', next: 'return'
      },
      {
        blankLine: 'always', prev: 'let', next: 'return'
      },
      {
        blankLine: 'always', prev: 'const', next: 'block'
      },
      {
        blankLine: 'always', prev: 'let', next: 'block'
      },
      {
        blankLine: 'always', prev: 'const', next: 'block-like'
      },
      {
        blankLine: 'always', prev: 'let', next: 'block-like'
      },
      {
        blankLine: 'always', prev: 'const', next: 'expression'
      },
      {
        blankLine: 'always', prev: 'let', next: 'expression'
      },

      // Newline before return
      {
        blankLine: 'always', prev: '*', next: 'return'
      },

      // Newline between imports and exports
      {
        blankLine: 'always', prev: 'import', next: 'export'
      }
    ],

    // Order imports
    // https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/order.md
    'import/order': ['error', {
      groups: [
        // 1. node "builtin" modules
        // ex: 'fs', 'path'
        'builtin',

        // 2. "external" modules
        // ex: 'axios', 'lodash'
        'external',

        // 3. "internal" modules
        // ex: 'src/foo'
        'internal',

        // 4. modules from a "parent" directory
        // ex: '../foo', '../../foo/qux'
        // AND
        // "sibling" modules from the same or a sibling's directory
        // ex: './bar', './bar/baz'
        ['sibling', 'parent'],

        // 5. "index" of the current directory
        // ex: './'
        'index'
      ],
      pathGroups: [
        // Place Vue imports after external packages
        {
          pattern: '{vue,vuex}',
          group: 'external',
          position: 'after'
        },

        // Place utilities after the "index" group
        {
          pattern: '{@/**,./**,../**,../../**,../../../**}/utils{/**,}',
          group: 'index',
          position: 'after'
        },

        // Consider all other paths starting with @ as internal modules
        {
          pattern: '@/**',
          group: 'internal',
          position: 'before'
        }
      ],
      pathGroupsExcludedImportTypes: ['builtin'],

      // Separate groups with newlines
      'newlines-between': 'always',

      // Sort imports alphabetically
      alphabetize: {
        order: 'asc',
        caseInsensitive: true
      }
    }],

    // Newline conditions for objects
    // https://eslint.org/docs/rules/object-curly-newline
    'object-curly-newline': ['error', {
      ObjectExpression: {
        multiline: true, minProperties: 2, consistent: true
      },
      ObjectPattern: {
        multiline: true
      },
      ImportDeclaration: {
        multiline: true, minProperties: 3
      },
      ExportDeclaration: {
        multiline: true, minProperties: 3
      }
    }],

    // Vue attributes order
    // https://eslint.vuejs.org/rules/attributes-order.html
    'vue/attributes-order': ['error', {
      order: [
        'DEFINITION',
        'LIST_RENDERING',
        'CONDITIONALS',
        'RENDER_MODIFIERS',
        'GLOBAL',
        ['UNIQUE', 'SLOT'],
        'TWO_WAY_BINDING',
        'OTHER_DIRECTIVES',
        'OTHER_ATTR',
        'EVENTS',
        'CONTENT'
      ],
      alphabetical: false
    }],

    // Do not require component names to be always multi-word
    // https://eslint.vuejs.org/rules/multi-word-component-names.html
    'vue/multi-word-component-names': 'off'
  }
}
