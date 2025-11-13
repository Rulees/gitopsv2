#!/usr/bin/env python3
import math

def parse_percent(p_raw: str) -> float:
    """
    Принимает '10%', '10', '0.1'.
    Возвращает долю (0.10).
    """
    s = str(p_raw).strip()
    if s.endswith('%'):
        return float(s[:-1]) / 100.0
    val = float(s)
    if val > 1:   # трактуем как проценты (10 -> 0.10)
        return val / 100.0
    return val

def compute_surge_count(N: int, P: float, min_surge: int = 1) -> int:
    """
    Формула: k >= (P*N)/(1-P)
    Возвращает ceil(k) с нижним порогом min_surge.
    """
    if N < 0:
        raise ValueError("N must be >= 0")
    if not (0.0 < P < 1.0):
        raise ValueError("P must be in (0,1)")
    k = (P * N) / (1.0 - P)
    return max(min_surge, math.ceil(k))
