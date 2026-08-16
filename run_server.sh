#!/bin/sh
# Inspector 調査用ラッパー: サーバーの stderr をファイルにも書き残す。
# exec で ruby に置き換わるので、プロセスの死に際の出力も確実に残る。
exec ruby server.rb 2>>server.stderr.log
