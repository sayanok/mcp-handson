#frozen_string_literal: true

# stdioトランスポート層。フレーミング(1行=1メッセージ)、UTF-8、JSONパースまでを
# 担当し、メッセージの意味は McpHandler(プロトコル層)に委ねる。
require "json"
require_relative "mcp_handler"

# MCP の stdio メッセージは UTF-8 と仕様で定められている。クライアントに起動される
# 子プロセスはシェルのロケール環境変数(LANG など)を引き継がないことがあり、
# その場合 Ruby は stdin/stdout を US-ASCII として扱い日本語で落ちるため、明示する。
$stdin.set_encoding(Encoding::UTF_8)
$stdout.set_encoding(Encoding::UTF_8)

# stdoutのバッファリングを無効化する。出力先がパイプの場合、規定では出力が
# まとめて書き出されるため、応答が即時にクライアントへ届くようにする
$stdout.sync = true

handler = McpHandler.new

$stderr.puts "[handson-mcp] server started (pid=#{Process.pid})"

$stdin.each_line do |line|
  next if line.strip.empty?

  begin
    msg = JSON.parse(line)
  rescue JSON::ParserError
    # 行を解釈できずidを取り出せないため、仕様に従いidはnullにする
    # フレーミングの事故なので、トランスポート層で返す
    $stdout.puts JSON.generate({ jsonrpc: "2.0", id: nil, error: { code:  -32700, message: "Parse error"}})
    next
  end

  response = handler.handle(msg)
  $stdout.puts JSON.generate(response) if response
end

$stderr.puts "[handson-mcp] stdin closed, exiting"
