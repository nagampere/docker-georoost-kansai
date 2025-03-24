#!/bin/bash

set -e

REPO_DIR="/app/repo"
ENV_FILE="$REPO_DIR/.env"
SECRETS_DIR="/app/.secrets"

mkdir -p "$SECRETS_DIR"

# === Git clone or pull ===
if [ ! -d "$REPO_DIR/.git" ]; then
  GITHUB_USERNAME=$(zenity --entry --title="GitHub Username" --text="GitHub ユーザー名を入力してください")
  GITHUB_PASSWORD=$(zenity --entry --title="GitHub Access Token" --text="GitHub アクセストークンを入力してください" --hide-text)
  zenity --info --text="初めてリポジトリをクローンしています..."
  git clone https://${GITHUB_USERNAME}:${GITHUB_PASSWORD}@github.com/nagampere/georoost-kansai.git "$REPO_DIR"
  cd "$REPO_DIR"
  zenity --info --text="poetry で依存関係をインストールしています..."
  poetry install --no-root
else
  cd "$REPO_DIR"
  zenity --info --text="最新の変更をプルしています..."
  git pull
  zenity --info --title="Pulling latest changes" --text="最新の変更をプルしています..."
fi


# === .env 初期作成 or アップロード ===
if [ ! -f "$ENV_FILE" ]; then
  MODE=$(zenity --list --radiolist \
    --title="Setup .env" \
    --text=".env ファイルが見つかりません。どうしますか？" \
    --column="選択" --column="方法" \
    TRUE "手動入力" \
    FALSE "ローカルファイルを選択" \
    FALSE "キャンセル")

  case "$MODE" in
    "手動入力")
      ACCESS_KEY=$(zenity --entry --title="AWS ACCESS KEY ID" --text="AWS-ACCESS-KEY-ID を入力してください" --hide-text)
      SECRET_KEY=$(zenity --entry --title="AWS SECRET ACCESS KEY" --text="AWS-SECRET-ACCESS-KEY を入力してください" --hide-text)
      REGION=$(zenity --entry --title="AWS DEFAULT REGION" --text="AWS-DEFAULT-REGION を入力してください")

      cat <<EOF > "$ENV_FILE"
AWS_ACCESS_KEY_ID=$ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$SECRET_KEY
AWS_DEFAULT_REGION=$REGION
EOF
      ;;

    "ローカルファイルを選択")
      SELECTED_FILE=$(zenity --file-selection --title="Select .env file")
      if [ -z "$SELECTED_FILE" ]; then
        zenity --error --text="ファイルが選択されませんでした。"
        exit 1
      fi

      cp "$SELECTED_FILE" "$ENV_FILE"

      zenity --text-info --filename="$ENV_FILE" --title=".env 内容確認"
      ;;

    *)
      zenity --info --text="セットアップをキャンセルしました。"
      exit 0
      ;;
  esac
fi

# === メインループ ===
while true; do
  ACTION=$(zenity --list --radiolist \
    --title="アクションを選択" \
    --text="何をしますか？" \
    --column="選択" --column="アクション" \
    TRUE "dbt を実行" \
    FALSE "Streamlit を開始" \
    FALSE "終了")

  case "$ACTION" in
    "dbt を実行")
      # .env 編集するか？
      DBT_OPTION=$(zenity --list --radiolist \
        --title="dbt オプション" \
        --text="dbt を実行する前に .env を編集しますか？" \
        --column="選択" --column="オプション" \
        TRUE "編集せずに実行" \
        FALSE ".env を編集して実行" \
        FALSE "キャンセル")

      case "$DBT_OPTION" in
        ".env を編集して実行")
          # 編集対象を選択
          ENV_VAR=$(zenity --list --radiolist \
            --title=".env 変数を編集" \
            --text="どの変数を編集しますか？" \
            --column="選択" --column="変数" \
            TRUE "AWS_ACCESS_KEY_ID" \
            FALSE "AWS_SECRET_ACCESS_KEY" \
            FALSE "AWS_DEFAULT_REGION")

          if [ -z "$ENV_VAR" ]; then
            zenity --error --text="変数が選択されていません。"
            continue
          fi

          # 現在値を取得
          CURRENT_VAL=$(grep "^$ENV_VAR=" "$ENV_FILE" | cut -d'=' -f2-)

          # 入力
          NEW_VAL=$(zenity --entry --title="$ENV_VAR を編集" --text="現在の値: $CURRENT_VAL\n新しい値を入力してください:")

          if [ -n "$NEW_VAL" ]; then
            sed -i "s|^$ENV_VAR=.*|$ENV_VAR=$NEW_VAL|" "$ENV_FILE"
          fi
          ;;
        "編集せずに実行")
          ;;
        *)
          continue  # キャンセル
          ;;
      esac

        export $(grep -v '^#' "$ENV_FILE" | xargs)

        zenity --info --text="dbt を実行しています..."

        if [ -d "$REPO_DIR/dbt" ] && [ -f "$REPO_DIR/dbt/dbt_project.yml" ]; then
            cd "$REPO_DIR/dbt"
            poetry run dbt deps || zenity --error --text="dbt deps に失敗しました"
            poetry run dbt run || zenity --error --text="dbt run に失敗しました"
            cd "$REPO_DIR"
        else
            zenity --error --text="リポジトリの dbt フォルダに dbt プロジェクトが見つかりません"
        fi
      ;;

    "Streamlit を開始")
      export $(grep -v '^#' "$ENV_FILE" | xargs)
      zenity --info --text="Streamlit を開始しています..."
      poetry run streamlit run services/streamlit/app.py --server.address=0.0.0.0 --server.port=8501 --server.headless true  > /app/streamlit.log 2>&1 &
      zenity --info --text="Streamlit が実行中です。http://localhost:8501 にアクセスしてください。\n\n Streamlit を停止するときは、[OK] をクリックして メインメニューに戻ります。"
      pkill -f "streamlit run"
      ;;

    "終了")
      zenity --info --text="アプリケーションを終了します。"
      exit 0
      ;;
  esac
done
