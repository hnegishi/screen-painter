cask "screen-painter" do
  version "1.0"
  # TODO: 初回リリース後、scripts/release.sh が出力する SHA256 に置き換えてください。
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/hnegishi/screen-painter/releases/download/v#{version}/ScreenPainter-#{version}.zip"
  name "Screen Painter"
  desc "Draw on the screen while holding a hotkey"
  homepage "https://github.com/hnegishi/screen-painter"

  depends_on macos: :ventura

  app "ScreenPainter.app"

  zap trash: [
    "~/Library/Caches/com.screenpainter.app",
    "~/Library/Preferences/com.screenpainter.app.plist",
  ]

  caveats <<~EOS
    ScreenPainter は署名されていないため、初回起動時に Gatekeeper にブロックされます。
    次のいずれかで起動できます:

      1) 「システム設定 → プライバシーとセキュリティ」を開き、下部に表示される
         『"ScreenPainter" は開発元を確認できないため…』の横の「このまま開く」をクリック

      2) はじめから quarantine を付けずにインストールする:
           brew install --cask --no-quarantine hnegishi/tap/screen-painter

    また、本アプリの動作には「アクセシビリティ」権限が必要です:
      システム設定 → プライバシーとセキュリティ → アクセシビリティ で
      ScreenPainter を許可してください。
      (署名なし版はアップデートのたびに再許可が必要になる場合があります)
  EOS
end
