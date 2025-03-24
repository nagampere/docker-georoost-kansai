#!/bin/bash

set -e

REPO_DIR="/app/repo"
ENV_FILE="$REPO_DIR/.env"
SECRETS_DIR="/app/.secrets"

mkdir -p "$SECRETS_DIR"

# === Git clone or pull ===
if [ ! -d "$REPO_DIR/.git" ]; then
  GITHUB_USERNAME=$(zenity --entry --title="GitHub Username" --text="Enter your GitHub username")
  GITHUB_PASSWORD=$(zenity --entry --title="GitHub Access Token" --text="Enter your GitHub access token" --hide-text)
  zenity --info --text="Cloning the repository for the first time..."
  git clone https://${GITHUB_USERNAME}:${GITHUB_PASSWORD}@github.com/nagampere/georoost-kansai.git "$REPO_DIR"
  cd "$REPO_DIR"
  zenity --info --text="Installing dependencies via poetry..."
  poetry install --no-root
else
  cd "$REPO_DIR"
  zenity --info --text="Pulling latest changes..."
  git pull
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
      ACCESS_KEY=$(zenity --entry --title="AWS ACCESS KEY ID" --text="Enter AWS_ACCESS_KEY_ID" --hide-text)
      SECRET_KEY=$(zenity --entry --title="AWS SECRET ACCESS KEY" --text="Enter AWS_SECRET_ACCESS_KEY" --hide-text)
      REGION=$(zenity --entry --title="AWS DEFAULT REGION" --text="Enter AWS_DEFAULT_REGION")

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
    --title="Select Action" \
    --text="What would you like to do?" \
    --column="Select" --column="Action" \
    TRUE "Run dbt" \
    FALSE "Start Streamlit" \
    FALSE "Exit")

  case "$ACTION" in
    "Run dbt")
      # .env 編集するか？
      DBT_OPTION=$(zenity --list --radiolist \
        --title="dbt Options" \
        --text="Edit .env before running dbt?" \
        --column="Select" --column="Option" \
        TRUE "Run without editing" \
        FALSE "Edit .env and run" \
        FALSE "Cancel")

      case "$DBT_OPTION" in
        "Edit .env and run")
          # 編集対象を選択
          ENV_VAR=$(zenity --list --radiolist \
            --title="Edit .env variable" \
            --text="Which variable do you want to edit?" \
            --column="Select" --column="Variable" \
            TRUE "AWS_ACCESS_KEY_ID" \
            FALSE "AWS_SECRET_ACCESS_KEY" \
            FALSE "AWS_DEFAULT_REGION")

          if [ -z "$ENV_VAR" ]; then
            zenity --error --text="No variable selected."
            continue
          fi

          # 現在値を取得
          CURRENT_VAL=$(grep "^$ENV_VAR=" "$ENV_FILE" | cut -d'=' -f2-)

          # 入力
          NEW_VAL=$(zenity --entry --title="Edit $ENV_VAR" --text="Current value: $CURRENT_VAL\nEnter new value:")

          if [ -n "$NEW_VAL" ]; then
            sed -i "s|^$ENV_VAR=.*|$ENV_VAR=$NEW_VAL|" "$ENV_FILE"
          fi
          ;;
        "Run without editing")
          ;;
        *)
          continue  # Cancel
          ;;
      esac

        export $(grep -v '^#' "$ENV_FILE" | xargs)

        zenity --info --text="Running dbt..."

        if [ -d "$REPO_DIR/dbt" ] && [ -f "$REPO_DIR/dbt/dbt_project.yml" ]; then
            cd "$REPO_DIR/dbt"
            poetry run dbt deps || zenity --error --text="dbt deps failed"
            poetry run dbt run || zenity --error --text="dbt run failed"
            cd "$REPO_DIR"
        else
            zenity --error --text="dbt project not found in repo/dbt"
        fi
      ;;

    "Start Streamlit")
      export $(grep -v '^#' "$ENV_FILE" | xargs)
      zenity --info --text="Starting Streamlit..."
      poetry run streamlit run services/streamlit/app.py --server.address=0.0.0.0 --server.port=8501 --server.headless true  > /app/streamlit.log 2>&1 &
      zenity --question --text="Streamlit is running. Click OK to stop Streamlit and return to the main menu."
      pkill -f "streamlit run"
      ;;

    "Exit")
      zenity --info --text="Exiting application."
      exit 0
      ;;
  esac
done
