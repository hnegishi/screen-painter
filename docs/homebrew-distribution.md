# Homebrew (個人 tap) での配布手順

ScreenPainter は GUI アプリなので、Homebrew では **Cask** として配布します。
公式 `homebrew/cask` への登録にはスター数などの知名度要件があるため、
ここでは審査不要の **個人 tap**(自分用のレシピ置き場リポジトリ)で配布します。

```
あなたが用意するもの
├── github.com/hnegishi/screen-painter      ← アプリ本体 + リリース(.zip 化した .app)
└── github.com/hnegishi/homebrew-tap        ← 個人 tap (Cask の置き場)
    └── Casks/screen-painter.rb             ← 「どこから何を入れるか」の定義

ユーザーがやること
└── brew install --cask hnegishi/tap/screen-painter
```

> このアプリは **署名なし(アドホック署名のみ)** で配布します。無料で始められますが、
> 初回起動時に Gatekeeper の許可操作が必要です(後述)。

---

## 0. 前提

- フルの Xcode がインストール済みであること(Command Line Tools だけでは不可)。
  - 確認: `xcode-select -p` が `/Applications/Xcode.app/...` を指していること。
  - 違う場合: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- GitHub CLI (`gh`) を使うと Release 作成を自動化できます: `brew install gh && gh auth login`

---

## 1. 一度だけ: tap リポジトリを作る

GitHub で **`homebrew-tap`** という名前のリポジトリを新規作成します
(名前は必ず `homebrew-` で始めること。短縮形でユーザーは `hnegishi/tap` と書けます)。

```bash
# 例: ローカルで作って push する場合
mkdir homebrew-tap && cd homebrew-tap
git init
mkdir Casks
# このリポジトリの Casks/screen-painter.rb をコピー
cp /path/to/screen-painter/Casks/screen-painter.rb Casks/
git add .
git commit -m "Add screen-painter cask"
git branch -M main
git remote add origin git@github.com:hnegishi/homebrew-tap.git
git push -u origin main
```

> Cask の本体は `screen-painter` リポジトリ内の `Casks/screen-painter.rb` を
> 「正本」として管理し、tap リポジトリへコピー/同期する運用にしています。

---

## 2. リリースする(毎回の作業)

### 手動でやる場合

```bash
# (必要ならバージョンを上げる: Xcode で MARKETING_VERSION を変更)

# ビルド → .zip 化 → SHA256 表示 → GitHub Release 作成までを一括
scripts/release.sh 1.0 --release
```

スクリプトが最後に出力する `version` と `sha256` を、
tap リポジトリの `Casks/screen-painter.rb` に反映します:

```ruby
version "1.0"
sha256  "(スクリプトが出力した SHA256)"
```

反映したらコミット&プッシュ:

```bash
cd /path/to/homebrew-tap
git commit -am "screen-painter 1.0"
git push
```

`--release` を付けない場合は、ビルドと SHA256 算出だけ行います。
その後 GitHub Release の作成と zip の添付を手動で行ってください。

### CI(GitHub Actions)で自動化する場合

`.github/workflows/release.yml` が用意してあります。次を一度だけ設定します:

1. `screen-painter` リポジトリの **Settings → Secrets and variables → Actions** で
   - **Variables** に `TAP_REPO` = `hnegishi/homebrew-tap`
   - **Secrets** に `TAP_REPO_TOKEN` = tap リポジトリへ push 権限を持つ PAT
     (GitHub の Personal Access Token。`homebrew-tap` への `contents: write` 権限)
2. あとはタグを打つだけ:

```bash
git tag v1.0
git push origin v1.0
```

これで「ビルド → Release 作成 → tap の Cask 更新」まで自動で走ります。
(`TAP_REPO` 未設定なら Cask 更新ステップはスキップされ、Release 作成だけ行います)

---

## 3. ユーザー側のインストール

```bash
# tap を登録(初回のみ)
brew tap hnegishi/tap

# インストール
brew install --cask screen-painter
# ↑ は次と同じ: brew install --cask hnegishi/tap/screen-painter
```

アップデート:

```bash
brew upgrade --cask screen-painter
```

アンインストール(設定ファイルも消す場合は `--zap`):

```bash
brew uninstall --cask --zap screen-painter
```

---

## 4. 署名なしゆえの注意点(ユーザーへ案内する内容)

- **初回起動で Gatekeeper にブロックされます。**
  「システム設定 → プライバシーとセキュリティ」を開き、下部の
  『"ScreenPainter" は開発元を確認できないため…』の横の **「このまま開く」** をクリック。
  - もしくは最初から quarantine を付けずに入れる:
    `brew install --cask --no-quarantine hnegishi/tap/screen-painter`
- **アクセシビリティ権限が必須**(描画機能に必要)。
  「システム設定 → プライバシーとセキュリティ → アクセシビリティ」で ScreenPainter を許可。
  - 署名なし版はアップデートのたびに再許可が必要になる場合があります。
    これを解消したい場合は、Apple Developer Program (年 $99) に加入して
    Developer ID 署名 + notarization を行う運用に切り替えてください。
