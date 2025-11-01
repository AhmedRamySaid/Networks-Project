using UnityEngine;

namespace UI_Components
{
    // Animation component for floating particles
    public class FloatingAnimation : MonoBehaviour
    {
        public float speed = 20f;
        public float amplitude = 100f;
        public float offset = 0f;
    
        private RectTransform rectTransform;
        private Vector2 startPosition;

        void Start()
        {
            rectTransform = GetComponent<RectTransform>();
            startPosition = rectTransform.anchoredPosition;
        }

        void Update()
        {
            float newY = startPosition.y + Mathf.Sin((Time.time * speed + offset) * 0.1f) * amplitude;
            rectTransform.anchoredPosition = new Vector2(startPosition.x, newY);
        }
    }
}