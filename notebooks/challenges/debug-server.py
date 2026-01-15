# type: ignore

import hashlib
import json
from random import randint

from Crypto.Util.number import getPrime, isPrime

flag_key = "U_WIN"
STARSCROLL = "HTB{" + f"{flag_key:_^79}" + "}"  # open("flag.txt").read()

assert len(STARSCROLL.strip("HTB{}")) == 79


class TinselRNG:
    def __init__(self, bits):
        self.holly_prime = getPrime(bits)
        self.sleigh_seed = randint(1, self.holly_prime)

    def sparkle_bit(self):
        if self.sleigh_seed == 0:
            self.sleigh_seed += 1
        while True:
            shimmer = pow(
                self.sleigh_seed, (self.holly_prime - 1) // 2, self.holly_prime
            )
            yield int(shimmer == 1)
            self.sleigh_seed = (self.sleigh_seed + 1) % self.holly_prime
            if self.sleigh_seed == 0:
                self.sleigh_seed += 1

    def gather_sparkles(self, n):
        bits = ""
        for i, b in enumerate(self.sparkle_bit()):
            if i == n:
                break
            bits += str(b)
        return int(bits, 2)


assert isPrime(
    FROST_PRIME := 0x1A66804D885939D7ACF3A4B413C9A24547B876E706913ADEC9684CC4A63AB0DFD2E0FD79F683DE06AD17774815DFC8375370EB3D0FB5DCE0019BD0632E7663A41
)


def frostscribe_signature(msg):
    blizzard = hashlib.sha512(msg.encode()).digest()
    snowmark = int.from_bytes(blizzard, "big") % FROST_PRIME
    lantern_key = frostrng.gather_sparkles(500)
    etch = pow(snowmark, lantern_key, FROST_PRIME)
    return {"signature": str(etch)}


frostrng = TinselRNG(34)  # 48

print(f"{frostrng.holly_prime=}")
print(f"{frostrng.sleigh_seed=}")

LIMIT = 2_000_000

print("Welcome to the Snowglobe Cipher Booth!\n")
while True:
    if LIMIT <= 0:
        print("The lantern dims for today...")
        break

    print("1) Etch Message Rune")
    print("2) Request Wrapped Starshard")
    print("3) Leave Booth")

    choice = input("> ").strip()

    if choice == "1":
        msg = input("Whisper your message: ")
        print(json.dumps(frostscribe_signature(msg)))
        LIMIT -= 1

    elif choice == "2":
        snow_otp = frostrng.gather_sparkles(len(STARSCROLL) * 8)
        user_otp = int(input("Reveal my snow-otp (in bits): "), 2)
        if user_otp == snow_otp:
            print(json.dumps({"starshard": STARSCROLL}))
        else:
            print(json.dumps({"starshard": "HTB{fake_flag_for_testing}"}))
        break

    elif choice == "3":
        print("May your lantern stay warm. Farewell...")
        break

    else:
        print("That choice jingled wrong.")
