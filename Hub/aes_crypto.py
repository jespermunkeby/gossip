from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os
"""
The following encyption/decryption methods use AES with GCM mode, it is a form of 
authenticated encryption suited for ensuring confidentiality as well as integrity of message.
Appended to the encrypted message is a 16 byte authentication tag used to check the message
integrity.

The encryption method requires a nonce to be sent with the message to be used as initialization
vector. In this case, the nonce is 12 bytes and is prepended to the encrypted message bytes. 
The nonce can be public without jeapordizing the security of the encrypted message.

In total, the size of the nonce (in this case 12) + the size of the authentication tag (always 16) 
= 28 bytes of "header" data is required for this implementation of the AES algorith with GCM mode.
"""

key = "7uG2KD5WYn0R3HcX1vMeZiPbELo8Af9x".encode('utf-8') # 256 bit (32 byte) key

def encrypt(plaintext):
    plaintext_bytes = plaintext.encode('utf8')
    init_vector = os.urandom(12) # NIST recommends a 96-bit IV length for best performance.
    aesgcm = AESGCM(key)
    cipher_text_bytes = aesgcm.encrypt(init_vector, plaintext_bytes, None) # additional unencrypted data set to none
    encrypted_msg = init_vector + cipher_text_bytes # Initialization vector appended to encrypted message
    return encrypted_msg


def decrypt(encrypted_msg):
    init_vector = encrypted_msg[:12] # Extract the initialization vector from the message
    cipher_text_bytes = encrypted_msg[12:] # Extract the ciphertext part of message
    aesgcm = AESGCM(key)
    decrypted_plaintext = aesgcm.decrypt(init_vector, cipher_text_bytes, None)
    return decrypted_plaintext