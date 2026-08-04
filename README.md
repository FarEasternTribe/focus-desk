# 集中デスク

GitHub Pagesで動く集中タイマー兼メモです。Supabaseを設定すると、同じメールアカウントでログインしたPC・スマートフォン間で、記録済みメモ、集中セッション、入力途中のメモを同期します。未ログイン時や通信できない場合も、従来どおりブラウザ内へ保存します。

## クラウド同期の初期設定

1. Supabaseでプロジェクトを作成します。
2. Supabaseの **SQL Editor** で [`supabase-schema.sql`](./supabase-schema.sql) を実行します。
3. **Authentication → URL Configuration** で Site URL を `https://fareasterntribe.github.io/focus-desk/` にし、同じURLを Redirect URLsにも追加します。
4. **Project Settings → API** の Project URL と publishable key（旧プロジェクトでは anon key）を [`supabase-config.js`](./supabase-config.js) に設定します。
5. 変更をGitHubへ反映します。公開画面でメールアドレスを入力し、届いたリンクを開くと同期が始まります。

`service_role` key は管理者権限を持つ秘密鍵なので、HTMLやJavaScriptへは絶対に入れないでください。ブラウザに置く publishable/anon key の権限は、`supabase-schema.sql` の Row Level Security によりログイン中の本人の行だけに制限されます。

## 同期の動作

- 記録、編集、削除はログイン中の他端末へリアルタイム反映されます。
- 入力途中のメモと作業名も約0.5秒後に保存されます。別端末で入力欄を操作中の場合は、その端末の入力を優先して上書きを避けます。
- 初回ログイン時には、そのブラウザに残っているローカル記録をクラウドへ統合します。
- 通信エラー時はローカルへ残り、次回の保存・表示復帰時に再同期します。
