using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Tests.EditMode
{
    public class DeflectSystemTests
    {
        private DeflectSystem CreateSystem(float perfect = 0.05f, float standard = 0.15f)
        {
            var go = new GameObject();
            var system = go.AddComponent<DeflectSystem>();
            // Use serialized field defaults or set via reflection if needed
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
    }
}
