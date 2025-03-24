# Welcome to docker-georoost-kansai!

こちらは、[GeoRoost-Kansai](https://github.com/nagampere/georoost-kansai)をDockerを使って起動するためのレポジトリです。GeoRoostはプライベートレポジトリなので、起動するには認証されたGithubアカウントとS3のアクセストークンが必要です。


# Setup

起動するには、以下の3つのステップにしたがってセットアップしてください。

1. Docker Desktop, XQuartzのインストール
2. Dockerイメージのビルド
3. Dockerコンテナの起動


# 1. Docker Desktop, XQuartzのインストール, 初期設定

## 1.1 インストール

MacOSの場合: [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)と[XQuartz](https://www.xquartz.org/)をインストール

Windowsの場合: [Docker Desktop for Win](https://www.docker.com/products/docker-desktop/)をインストール

## 1.2 Docker Desktopの設定

Setting > Resources > Advancedで、dockerに割り当てるCPU・メモリを設定する。

CPUに4、メモリに8GBを割り当てる。

## 1.3 XQuartzの設定

XQuartz メニュー → Preferences → Security タブを開いて：

☑️ 「Allow connections from network clients」 をチェック

その後、XQuartz を再起動

# 2. Dockerイメージのビルド

## docker cloudからビルドする場合(推奨)

docker desktopを起動後、上部のSearchで「nagampere0508/docker-georoost-kansai」と検索し「Pull」をクリック

![Image 1](images/pic_docker_desktop_1.png)

# 3. Dockerコンテナの起動

## 1.1 ターミナルからコマンドで起動

docker desktopの下部にある「>_」をクリックしてターミナルを展開し、下記のコマンドを入力する。

```{bash}
% xhost + 127.0.0.1
% docker run -p 8501:8501 -e DISPLAY=host.docker.internal:0 nagampere0508/docker-georoost-kansai
```
![Image 2](images/pic_docker_desktop_2.png)

## 1.2 Githubアカウントの認証

GUIの指示にしたがって、「Github ユーザー名」、「Github アクセストークン」を入力し、リポジトリのクローンと依存関係のインストールを行う。以降、「OK」をクリックしないと先に進まない。

依存関係のインストールには3分程度かかり、終了したらGUIが再び開く。

![Image 3](images/pic_GUI_1.png)

※ 「control + v」でペーストできないときは、右クリックから実行できる。

※ 左のタブからContainersを開き、立ち上がったコンテナをクリックしてログを確認すると分かりやすい。

## 1.3 .envファイルの設定

「手動入力」を選択し、「AWS-ACCESS-KEY-ID」、「AWS-SECRET-ACCESS-KEY」、「AWS-DEFAULT-REGION」を入力し、「dbtを実行」>「編集せずに実行」を選択。

dbtの実行完了には3分程度かかり、終了したらGUIが再び開く。

![Image 4](images/pic_GUI_2.png)

##  1.4 streamlitの設定

「Streamlitを開始」を選択し、OKを押して、http://localhost:8501/ をブラウザで開く。

![Image 5](images/pic_GUI_3.png)