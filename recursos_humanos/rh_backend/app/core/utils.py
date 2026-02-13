import random
import string

def generate_code(length: int = 6):
    return ''.join(random.choices(string.digits, k=length))
