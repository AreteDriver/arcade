using System.Reflection;
using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Tests.EditMode
{
    public class DeflectSystemTests
    {
        private const float DefaultPerfectWindow = 0.05f;
        private const float DefaultStandardWindow = 0.15f;

        private DeflectSystem CreateSystem(float perfect = DefaultPerfectWindow, float standard = DefaultStandardWindow)
        {
            var go = new GameObject();
            var system = go.AddComponent<DeflectSystem>();

            // Set serialized fields via reflection for test control
            var type = typeof(DeflectSystem);
            var perfectField = type.GetField("_perfectWindow", BindingFlags.NonPublic | BindingFlags.Instance);
            var standardField = type.GetField("_standardWindow", BindingFlags.NonPublic | BindingFlags.Instance);

            perfectField?.SetValue(system, perfect);
            standardField?.SetValue(system, standard);

            return system;
        }

        [Test]
        public void DeflectSystem_EvaluateWindow_Perfect()
        {
            var system = CreateSystem();

            var result = system.EvaluateWindow(0.03f);

            Assert.That(result, Is.EqualTo(DeflectResult.Perfect));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_EvaluateWindow_Standard()
        {
            var system = CreateSystem();

            var result = system.EvaluateWindow(0.1f);

            Assert.That(result, Is.EqualTo(DeflectResult.Standard));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_EvaluateWindow_Miss()
        {
            var system = CreateSystem();

            var result = system.EvaluateWindow(0.2f);

            Assert.That(result, Is.EqualTo(DeflectResult.Miss));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_PerfectAtBoundary()
        {
            var system = CreateSystem();

            var result = system.EvaluateWindow(0.05f);

            Assert.That(result, Is.EqualTo(DeflectResult.Perfect));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_StandardAtBoundary()
        {
            var system = CreateSystem();

            var result = system.EvaluateWindow(0.15f);

            Assert.That(result, Is.EqualTo(DeflectResult.Standard));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_MeterGain_Perfect()
        {
            var system = CreateSystem();

            var gain = system.GetMeterGain(DeflectResult.Perfect);

            Assert.That(gain, Is.GreaterThan(0));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_MeterGain_Miss_Zero()
        {
            var system = CreateSystem();

            var gain = system.GetMeterGain(DeflectResult.Miss);

            Assert.That(gain, Is.EqualTo(0));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_StaggerDuration_PerfectGreaterThanStandard()
        {
            var system = CreateSystem();

            var perfect = system.GetStaggerDuration(DeflectResult.Perfect);
            var standard = system.GetStaggerDuration(DeflectResult.Standard);

            Assert.That(perfect, Is.GreaterThan(standard));
            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_CustomWindows_RespectedByEvaluate()
        {
            // Use custom window values to verify the factory applies them
            var system = CreateSystem(perfect: 0.1f, standard: 0.3f);

            // 0.08f would be Miss with default 0.05f, but Perfect with 0.1f
            Assert.That(system.EvaluateWindow(0.08f), Is.EqualTo(DeflectResult.Perfect));
            // 0.2f would be Miss with default 0.15f, but Standard with 0.3f
            Assert.That(system.EvaluateWindow(0.2f), Is.EqualTo(DeflectResult.Standard));
            // 0.35f should be Miss even with extended windows
            Assert.That(system.EvaluateWindow(0.35f), Is.EqualTo(DeflectResult.Miss));

            Object.DestroyImmediate(system.gameObject);
        }

        [Test]
        public void DeflectSystem_WindowProperties_MatchConfigured()
        {
            var system = CreateSystem(perfect: 0.08f, standard: 0.25f);

            Assert.That(system.PerfectWindow, Is.EqualTo(0.08f));
            Assert.That(system.StandardWindow, Is.EqualTo(0.25f));

            Object.DestroyImmediate(system.gameObject);
        }
    }
}
