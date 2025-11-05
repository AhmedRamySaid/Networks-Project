using System;
using System.Collections.Generic;
using UnityEngine;

namespace Networks
{
    public class UnityMainThreadDispatcher : MonoBehaviour
    {
        private static UnityMainThreadDispatcher instance;
        private static readonly Queue<Action> Actions = new Queue<Action>();

        private void Awake()
        {
            if (instance != null && instance != this)
            {
                Destroy(this.gameObject); // ensure only one exists
                return;
            }

            instance = this;
            DontDestroyOnLoad(this.gameObject);
        }

        /// <summary>
        /// Access the dispatcher instance (must exist in the scene)
        /// </summary>
        public static UnityMainThreadDispatcher Instance()
        {
            if (instance == null)
                throw new Exception("UnityMainThreadDispatcher must exist in the scene!");
            return instance;
        }

        /// <summary>
        /// Enqueue an action to run on the main Unity thread
        /// </summary>
        public void Enqueue(Action action)
        {
            lock (Actions)
            {
                Actions.Enqueue(action);
            }
        }

        private void Update()
        {
            lock (Actions)
            {
                while (Actions.Count > 0)
                {
                    Actions.Dequeue().Invoke();
                }
            }
        }
    }
}