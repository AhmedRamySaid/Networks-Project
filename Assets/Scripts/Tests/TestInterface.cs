namespace Networks
{
    using UnityEngine;
    using UnityEngine.SceneManagement;
    using System;

    public class TestInterface : MonoBehaviour
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        static void LoadSceneFromArgs()
        {
            string[] args = Environment.GetCommandLineArgs();
            for (int i = 0; i < args.Length - 1; i++)
            {
                if (args[i] == "-scene")
                {
                    string sceneName = args[i + 1];
                    Debug.Log($"[CommandLineSceneLoader] Loading scene: {sceneName}");
                    SceneManager.LoadScene(sceneName);
                    return;
                }
            }

            Debug.Log("[CommandLineSceneLoader] No -scene argument, using default startup scene.");
        }
    }

}