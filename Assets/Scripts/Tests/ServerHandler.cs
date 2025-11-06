using Networks;
using UnityEngine;

namespace Tests
{
    public class ServerHandler : MonoBehaviour
    {
        public void Awake()
        {
            Server server = new Server();
            server.InitializeServer();
        }
    }
}