using TMPro;
using UnityEngine;

namespace UI_Components
{
    // Animation component for title glow
    public class GlowAnimation : MonoBehaviour
    {
        private TextMeshProUGUI textComponent;
        private float glowSpeed = 2f;

        void Start()
        {
            textComponent = GetComponent<TextMeshProUGUI>();
        }

        void Update()
        {
            float alpha = 0.7f + Mathf.Sin(Time.time * glowSpeed) * 0.3f;
            Color outlineColor = textComponent.outlineColor;
            outlineColor.a = alpha;
            textComponent.outlineColor = outlineColor;
        }
    }
}