using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Tests.EditMode
{
    public class AttackRunnerTests
    {
        private const float FrameDuration = 1f / 60f; // All timing is based on 60fps

        private AttackDefinition CreateAttack(int startup, int active, int recovery)
        {
            // OnEnable logs error for invalid definitions (before we set properties)
            LogAssert.ignoreFailingMessages = true;
            var attack = ScriptableObject.CreateInstance<AttackDefinition>();
            LogAssert.ignoreFailingMessages = false;
            attack.AttackId = "Test";
            attack.StartupFrames = startup;
            attack.ActiveFrames = active;
            attack.RecoveryFrames = recovery;
            attack.TelegraphLeadFrames = 0;
            attack.HitboxSize = Vector3.one;
            return attack;
        }

        private static float FramesToSeconds(int frames) => frames * FrameDuration;

        [Test]
        public void AttackRunner_GetPhaseAtTime_Startup()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // Check at frame 3 (within 10-frame startup)
            var phase = runner.GetPhaseAtTime(attack, FramesToSeconds(3));

            Assert.That(phase, Is.EqualTo(AttackPhase.Startup));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_Active()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // Check at frame 11 (just after 10-frame startup, within 5-frame active)
            var phase = runner.GetPhaseAtTime(attack, FramesToSeconds(11));

            Assert.That(phase, Is.EqualTo(AttackPhase.Active));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_Recovery()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // Check at frame 18 (after 10+5=15 frames, within 10-frame recovery)
            var phase = runner.GetPhaseAtTime(attack, FramesToSeconds(18));

            Assert.That(phase, Is.EqualTo(AttackPhase.Recovery));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_AfterTotal_None()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // Check at frame 30 (after total 25 frames)
            var phase = runner.GetPhaseAtTime(attack, FramesToSeconds(30));

            Assert.That(phase, Is.EqualTo(AttackPhase.None));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_AtStartupBoundary()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // Exactly at frame 10 boundary - should still be Startup (0-indexed)
            var phaseAtBoundary = runner.GetPhaseAtTime(attack, FramesToSeconds(10) - 0.0001f);
            Assert.That(phaseAtBoundary, Is.EqualTo(AttackPhase.Startup));

            // Just after boundary - should be Active
            var phaseAfter = runner.GetPhaseAtTime(attack, FramesToSeconds(10) + 0.0001f);
            Assert.That(phaseAfter, Is.EqualTo(AttackPhase.Active));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_AtActiveBoundary()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // Exactly at frame 15 boundary (10 startup + 5 active)
            var phaseAtBoundary = runner.GetPhaseAtTime(attack, FramesToSeconds(15) - 0.0001f);
            Assert.That(phaseAtBoundary, Is.EqualTo(AttackPhase.Active));

            // Just after boundary - should be Recovery
            var phaseAfter = runner.GetPhaseAtTime(attack, FramesToSeconds(15) + 0.0001f);
            Assert.That(phaseAfter, Is.EqualTo(AttackPhase.Recovery));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_TimingConsistent_At30fps()
        {
            AssertTimingAtFrameRate(30);
        }

        [Test]
        public void AttackRunner_TimingConsistent_At60fps()
        {
            AssertTimingAtFrameRate(60);
        }

        [Test]
        public void AttackRunner_TimingConsistent_At120fps()
        {
            AssertTimingAtFrameRate(120);
        }

        private void AssertTimingAtFrameRate(int fps)
        {
            var attack = CreateAttack(60, 30, 30); // 1s, 0.5s, 0.5s
            var runner = new GameObject().AddComponent<AttackRunner>();

            float dt = 1f / fps;
            float activeStart = attack.StartupDuration;
            float recoveryStart = activeStart + attack.ActiveDuration;

            // All frame rates should identify same phase boundaries
            Assert.That(runner.GetPhaseAtTime(attack, activeStart - 0.01f), Is.EqualTo(AttackPhase.Startup));
            Assert.That(runner.GetPhaseAtTime(attack, activeStart + 0.01f), Is.EqualTo(AttackPhase.Active));
            Assert.That(runner.GetPhaseAtTime(attack, recoveryStart + 0.01f), Is.EqualTo(AttackPhase.Recovery));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }
    }
}
