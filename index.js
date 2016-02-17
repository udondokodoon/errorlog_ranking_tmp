var http = require("http");
var exec = require("child_process").exec;

http.createServer(function(req, res) {
  res.writeHead(200, {"Content-Type": "text/html"});
  exec("gzip -d -c /var/log/nginx/get.log-`date +%Y%m%d -d yesterday`.gz | cat - /var/log/nginx/get.log | perl .log_read.pl | perl .log_trans.pl", { encoding: "utf8", maxBuffer: 1024 * 1024 * 1024}, function(err, stdout, stderr) {
    if (err) { res.end(err.getMessage()) }
    var list = stdout.split("\n");
    res.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"><script src=\"https://code.jquery.com/jquery-2.2.0.min.js\"></script><link rel=\"stylesheet\" type=\"text/css\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\"><script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js\"></script></head><body><table border=1>");
    res.write("<tr><th>ランク</th><th>カウント</th><th>ロケーション</th><th>エラー</th><th>ヒストリ</th></tr>")
    list.forEach(function(d, i) {
      if (!d) {return}
      var cols = d.split("\t");
      if (cols.length < 2) { throw new Error(d); }
      var err = JSON.parse(cols[2]);
      var param = {
        rank: i + 1,
        count: err.count,
        digest: cols[0],
        error: JSON.stringify(err.record.error, null, "  "),
        location: JSON.stringify(err.record.status.location.replace(/\?.+/, ""), null, "  "),
        history: JSON.stringify(err.record.history, null, "  ")
      };
      res.write("<tr><td style=\"font-size: 30px;vertical-align:top\"><a name=\"{{rank}}\" href=\"#{{rank}}\">{{rank}}</a></td><td>{{count}}</td><td><pre>{{location}}</pre></td><td><pre>{{error}}</pre><a href=\"javascript:void(0)\" onclick=\"document.getElementById('{{digest}}_history').style.display = 'table-cell'\">history</a></td><td id=\"{{digest}}_history\" style=\"display: none\"><pre>{{history}}</pre><a href=\"javascript:void(0)\" onclick=\"this.parentNode.style.display = 'none'\">close</a></td></tr>".replace(/{{(\w+)}}/g, function(m, m1) {
        return param[m1] || "";
      }));
    });
    res.write("</table></body></html>");
    res.end("");
  });
}).listen(8080);
