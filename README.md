# Screen Painter

macOS向けのスクリーンペインターアプリ。特定のキーを押しながらマウスを操作することで、画面上に自由に落書きができます。

https://github.com/user-attachments/assets/372f6b72-7d58-460f-a8d0-b2ce0423ac69

## 機能

- **ホットキー + マウスドラッグ**で画面上に描画（デフォルト: Left Control）
- **長押しモード**: キーを押している間だけ描画可能
- **切り替えモード**: キーを押すたびに描画ON/OFFを切り替え
- 描画は設定した秒数後に**自動でフェードアウト**（デフォルト: 3秒）
- **Escape**キーで描画を即座にクリア
- メニューバー常駐型

## 設定でカスタマイズ可能な項目

| 項目               | デフォルト値 |
| ------------------ | ------------ |
| 描画キー           | Left Control |
| クリアキー         | Escape       |
| 描画モード         | 長押し       |
| ペイントの色       | 緑           |
| 線の太さ           | 3.0          |
| 自動消去までの秒数 | 3.0秒        |

## 動作環境

- macOS 13.0 (Ventura) 以降

## インストール

Homebrew (個人 tap) でインストールできます。

```bash
brew install --cask hnegishi/tap/screen-painter
```

> 署名なしで配布しているため、初回起動時に Gatekeeper にブロックされます。
> 「システム設定 → プライバシーとセキュリティ」の下部にある「このまま開く」をクリックするか、
> `brew install --cask --no-quarantine hnegishi/tap/screen-painter` でインストールしてください。

リリース・配布の仕組みについては [docs/homebrew-distribution.md](docs/homebrew-distribution.md) を参照してください。

## ビルド方法

### Xcodeで開く

```bash
open ScreenPainter.xcodeproj
```

Xcode上で **Cmd+R** でビルド&実行。

## セットアップ

1. アプリを起動すると、アクセシビリティ権限の許可ダイアログが表示されます
2. **システム設定 > プライバシーとセキュリティ > アクセシビリティ** からScreenPainterを許可
3. メニューバーのペイントブラシアイコンからお好みの設定に変更
