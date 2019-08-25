const proxy = require('http-proxy-middleware');

module.exports = function (app) {
  app.use(proxy('/ui', { target: 'http://localhost:2333' }));
  app.use(proxy('/MATT-io', { target: 'ws://localhost:2333' }));
};
