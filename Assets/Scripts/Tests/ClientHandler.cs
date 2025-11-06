using Networks;
using UnityEngine;

namespace Tests
{
    public class ClientHandler : MonoBehaviour
    {
        public void Awake()
        {
            Client client = new Client("127.0.0.1");
        }
    }
}