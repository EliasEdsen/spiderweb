var path = require('path');
var webpack = require('webpack');
var HtmlPlugin = require('html-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var rimraf = require('rimraf');

var _publicPath = process.env.NODE_ENV === 'dev'? '/' : './';

function addHash(template, hash) {
  return template.replace(/\.[^.]+$/, `.[${hash}]$&`)
}

module.exports = {
  context: path.resolve(__dirname, 'src'),

  entry: './scripts/index.coffee',

  output: {
    path: path.resolve(__dirname, 'dist'),
    publicPath: _publicPath,
    filename: addHash('scripts/[name].js', 'chunkhash:5')
  },

  resolve: {
  },

  module: {
    rules: [
      {
        test: /\.jade$/,
        loader: 'jade-loader?pretty=true',
        exclude: [
          path.resolve(__dirname, 'node_modules'),
          path.resolve(__dirname, 'assets')
        ]
      },
      {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract({
          fallbackLoader: 'style-loader',
          loader: 'css-loader!autoprefixer-loader?browsers=last 50 versions',
          publicPath: '../'
        }),
        exclude: [
          path.resolve(__dirname, 'node_modules'),
          path.resolve(__dirname, 'assets')
        ]
      },
      {
        test: /\.styl$/,
        loader: ExtractTextPlugin.extract({
          fallbackLoader: 'style-loader',
          loader: 'css-loader!autoprefixer-loader?browsers=last 50 versions!stylus-loader?resolve url',
          publicPath: '../'
        }),
        exclude: [
          path.resolve(__dirname, 'node_modules'),
          path.resolve(__dirname, 'assets')
        ]
      },
      {
        test: /\.js$/,
        loader: 'babel-loader',
        exclude: [
          path.resolve(__dirname, 'node_modules'),
          path.resolve(__dirname, 'assets')
        ]
      },
      {
        test: /\.coffee$/,
        loader: 'coffee-loader',
        exclude: [
          path.resolve(__dirname, 'node_modules'),
          path.resolve(__dirname, 'assets')
        ]
      },
      {
        test: /.*/,
        loader: 'file-loader',
        include: path.resolve(__dirname, 'src', 'assets', 'images'),
        options: {
          name: '[path][name].[hash:5].[ext]'
        }
      },
      {
        test: /.*/,
        loader: 'file-loader',
        include: path.resolve(__dirname, 'src', 'assets', 'fonts'),
        options: {
          name: '[path][name].[ext]'
        }
      }
    ]
  },

  devServer: {
    historyApiFallback: true,
    noInfo: true
  },

  performance: {
    hints: false
  },

  plugins: [
    {
      apply: function function_name(compiler) {
        rimraf.sync(compiler.options.output.path);
      }
    },
    new CopyWebpackPlugin([
      { from: './assets/libs/*' }
    ])
  ]
}

if (process.env.NODE_ENV === 'dev' || process.env.NODE_ENV === 'test') {
  module.exports.devtool = 'eval-source-map'
  module.exports.plugins = (module.exports.plugins || []).concat([
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: '"development"'
      }
    }),
    new HtmlPlugin({
      filename: 'index.html',
      favicon: './assets/images/favicon.ico',
      minify: false,
      cache: true,
      template: './index.jade',
      xhtml: true
    }),
    new ExtractTextPlugin({
      filename: addHash('styles/[name].css', 'chunkhash:5'),
      allChunks: true
    })
  ])
}

if (process.env.NODE_ENV === 'prod') {
  module.exports.devtool = 'source-map'
  module.exports.plugins = (module.exports.plugins || []).concat([
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: '"production"'
      }
    }),
    new HtmlPlugin({
      filename: 'index.html',
      favicon: './assets/images/favicon.ico',
      minify: { collapseWhitespace: true },
      cache: true,
      template: './index.jade',
      xhtml: true
    }),
    new ExtractTextPlugin({
      filename: addHash('styles/[name].css', 'chunkhash:5'),
      allChunks: true
    }),
    new webpack.optimize.UglifyJsPlugin({
      sourceMap: true,
      compress: {
        warnings: false
      }
    }),
    new webpack.LoaderOptionsPlugin({
      minimize: true
    })
  ])
}
