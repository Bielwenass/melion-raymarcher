const { defineConfig } = require('@vue/cli-service')

module.exports = defineConfig({
  transpileDependencies: true,
  configureWebpack: {
    module: {
      rules: [
        {
          test: /\.glsl$/,
          loader: 'webpack-glsl-loader'
        }
      ]
    }
  }
})
