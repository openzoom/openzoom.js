const path = require('path')


// Main
module.exports = {
  resolve: {
    extensions: ['', '.js'],
  },
  entry: {
    main: './src/OpenZoom.js',
  },
  output: {
    filename: './lib/openzoom.js',
    library: 'openzoom',
    libraryTarget: 'umd',
  },
  module: {
    loaders: [
      {
        loader: 'babel-loader',
        include: [
          path.resolve(__dirname, 'src'),
        ],
        test: /\.js$/,
        query: {
          plugins: ['transform-runtime'],
          presets: ['es2015', 'stage-0'],
        },
      },
    ],
  },
}
