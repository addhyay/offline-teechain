from web3 import Web3
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature, decode_dss_signature

class SimTEE:

    def __init__(self): # returns the local address of the node
        self.private_key = ec.generate_private_key(ec.SECP256R1())
        self.public_key = self.private_key.public_key()
        return Web3.keccak(self.public_key.public_bytes())


    def sign(self, message: bytes) -> bytes:
        digest = Web3.keccak(message)
        signature = self.private_key.sign(digest, ec.ECDSA(hashes.SHA256()))
        return signature
    
    def verify(self, message: bytes, signature: bytes) -> bool:
        try:
            digest = Web3.keccak(message)
            self.public_key.verify(signature, digest, ec.ECDSA(hashes.SHA256()))
            return True
        except:
            print("[TEE] :: Signature verification failed.")
            return False
        
    def getPublicKey(self) -> bytes:
        pubBytes = self.public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        return pubBytes.decode()