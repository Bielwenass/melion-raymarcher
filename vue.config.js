module.exports = {
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
}
