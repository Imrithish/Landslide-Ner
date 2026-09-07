import database
from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordRequestForm
from schemas.auth import UserRegisterRequest, UserLoginRequest, TokenResponse, UserResponse
from services.auth_service import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter()


@router.post("/auth/register", response_model=TokenResponse)
async def register_user(req: UserRegisterRequest):
    """
    Public registration always creates a CITIZEN account.
    Administrative roles (AUTHORITY, ADMIN) must be provisioned by an administrator.
    """
    if database._pool is None:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    hashed = hash_password(req.password)
    with database.get_db() as cur:
        cur.execute("SELECT id FROM users WHERE email = %s", (req.email,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")

        # Force role to CITIZEN to prevent privilege escalation
        assigned_role = "CITIZEN"

        cur.execute(
            """
            INSERT INTO users (email, hashed_password, full_name, phone_number, role, state, district)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (req.email, hashed, req.full_name, req.phone_number, assigned_role, req.state, req.district)
        )
        user_id = cur.lastrowid
        cur.execute("SELECT id, email, full_name, phone_number, role, state, district, created_at FROM users WHERE id = %s", (user_id,))
        user = cur.fetchone()

    user_resp = UserResponse(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        phone_number=user["phone_number"],
        role=user["role"],
        state=user["state"],
        district=user["district"],
        created_at=user["created_at"].isoformat() + "Z",
    )
    token = create_access_token({"sub": user["id"], "role": user["role"]})
    return TokenResponse(access_token=token, user=user_resp)


@router.post("/auth/login", response_model=TokenResponse)
async def login_user(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    Standard OAuth2 password login endpoint compatible with Swagger UI Authorize popup and JSON clients.
    """
    if database._pool is None:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    with database.get_db() as cur:
        cur.execute("SELECT id, email, hashed_password, full_name, phone_number, role, state, district, created_at FROM users WHERE email = %s", (form_data.username,))
        user = cur.fetchone()

    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    user_resp = UserResponse(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        phone_number=user["phone_number"],
        role=user["role"],
        state=user["state"],
        district=user["district"],
        created_at=user["created_at"].isoformat() + "Z",
    )
    token = create_access_token({"sub": user["id"], "role": user["role"]})
    return TokenResponse(access_token=token, user=user_resp)


from schemas.auth import UserRegisterRequest, UserLoginRequest, TokenResponse, UserResponse, UserUpdateRequest

@router.get("/auth/me", response_model=UserResponse)
async def get_me(user: dict = Depends(get_current_user)):
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return UserResponse(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        phone_number=user.get("phone_number"),
        role=user["role"],
        state=user.get("state"),
        district=user.get("district"),
        created_at=user["created_at"].isoformat() + "Z" if hasattr(user["created_at"], "isoformat") else str(user["created_at"]),
    )


@router.put("/auth/me", response_model=UserResponse)
async def update_me(
    req: UserUpdateRequest,
    user: dict = Depends(get_current_user)
):
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    if database._pool is None:
        raise HTTPException(status_code=503, detail="Database service currently unavailable")

    user_id = user["id"]
    with database.get_db() as cur:
        updates = []
        params = []
        if req.full_name is not None:
            updates.append("full_name = %s")
            params.append(req.full_name)
        if req.phone_number is not None:
            updates.append("phone_number = %s")
            params.append(req.phone_number)
        if req.state is not None:
            updates.append("state = %s")
            params.append(req.state)
        if req.district is not None:
            updates.append("district = %s")
            params.append(req.district)

        if updates:
            params.append(user_id)
            cur.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = %s", tuple(params))

        cur.execute("SELECT id, email, full_name, phone_number, role, state, district, created_at FROM users WHERE id = %s", (user_id,))
        updated_user = cur.fetchone()

    return UserResponse(
        id=updated_user["id"],
        email=updated_user["email"],
        full_name=updated_user["full_name"],
        phone_number=updated_user.get("phone_number"),
        role=updated_user["role"],
        state=updated_user.get("state"),
        district=updated_user.get("district"),
        created_at=updated_user["created_at"].isoformat() + "Z" if hasattr(updated_user["created_at"], "isoformat") else str(updated_user["created_at"]),
    )
