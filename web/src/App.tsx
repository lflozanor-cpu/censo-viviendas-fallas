import { useState } from 'react'
import Dashboard from './Dashboard'
import Login from './Login'

const API_BASE = 'http://localhost:8000/api'

export function getToken(): string | null {
  return localStorage.getItem('token')
}

export function setToken(token: string) {
  localStorage.setItem('token', token)
}

export function clearToken() {
  localStorage.removeItem('token')
}

export { API_BASE }

export default function App() {
  const [token, setTokenState] = useState<string | null>(getToken())

  const onLogin = (t: string) => {
    setToken(t)
    setTokenState(t)
  }

  const onLogout = () => {
    clearToken()
    setTokenState(null)
  }

  if (!token) {
    return <Login onLogin={onLogin} />
  }

  return <Dashboard token={token} onLogout={onLogout} />
}
