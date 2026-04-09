from __future__ import annotations
import hashlib
from typing import Any, Dict, Optional
from fastapi import APIRouter, Request
import firebase_admin
from firebase_admin import firestore, credentials

# --- 窓口（router）の定義 ---
router = APIRouter()

def get_db():
    try:
        firebase_admin.get_app()
    except ValueError:
        # 見つかった正しいパスを指定します
        cred_path = "/opt/poikatsu/secrets/firebase-admin.json"
        
        try:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print("DEBUG: Firebase initialized with service account.")
        except Exception as e:
            print(f"DEBUG: Firebase init error: {e}")
            firebase_admin.initialize_app()
            
    return firestore.client()

@router.get("/ad/cv")
async def skyflag_callback(request: Request):
    params = dict(request.query_params)
    print(f"DEBUG Skyflag Production Callback received: {params}")
    
    uid = params.get("uid")
    point = params.get("point")
    adid = params.get("adid")
    
    # データベースへの接続を取得
    try:
        db = get_db()
        result = grant_skyflag_points(
            db=db,
            uid=uid,
            point=point,
            adid=adid,
            raw_params=params
        )
        print(f"DEBUG Result: {result}")
    except Exception as e:
        print(f"ERROR in grant_points: {e}")
        # エラーが起きてもSkyflag側には一旦成功を返しておく（再送地獄を防ぐため）
    
    return "1"

# --- 以下、ポイント付与ロジック ---
def _normalize_int_point(value: Any) -> int:
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return 0

def _pick_tx_id(params: Dict[str, Any]) -> str:
    for k in ("transaction_id", "txid", "mcv_no", "adid", "xid"):
        v = params.get(k)
        if v is not None and str(v).strip():
            return str(v).strip()
    return ""

def grant_skyflag_points(
    *,
    db: Any,
    uid: str,
    point: Any,
    adid: Optional[str] = None,
    mcv_no: Optional[str] = None,
    raw_params: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    if not uid or not str(uid).strip():
        return {"ok": True, "awarded": False, "reason": "missing_uid"}
    
    points_int = _normalize_int_point(point)
    if points_int <= 0:
        return {"ok": True, "awarded": False, "reason": "zero_or_invalid_point"}
    
    params = dict(raw_params or {})
    tx_id = _pick_tx_id(params) or (mcv_no or "") or (adid or "")
    
    # 重複防止用IDの作成
    dedup_base = f"{uid}|{adid or ''}|{tx_id}"
    dedup_doc_id = hashlib.sha256(dedup_base.encode("utf-8")).hexdigest()
    
    awards_ref = db.collection("skyflag_awards").document(dedup_doc_id)
    user_ref = db.collection("users").document(uid)
    
    award_doc = {
        "uid": uid,
        "point": points_int,
        "txId": tx_id,
        "timestamp": firestore.SERVER_TIMESTAMP,
        "raw": params
    }
    
    try:
        # 重複チェック（すでにドキュメントがあれば例外が発生する）
        awards_ref.create(award_doc)
        # ユーザーのポイントを加算
        user_ref.update({"totalPoints": firestore.Increment(points_int)})
        return {"ok": True, "awarded": True}
    except Exception as e:
        if "AlreadyExists" in str(e) or "already exists" in str(e).lower():
            return {"ok": True, "awarded": False, "reason": "duplicate"}
        raise e
