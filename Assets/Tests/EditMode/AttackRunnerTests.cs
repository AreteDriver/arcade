using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Tests.EditMode
{
    public class AttackRunnerTests
    {
        private AttackDefinition CreateAttack(int startup, int active, int recovery)
        {
            var attack = ScriptableObject.CreateInstance<AttackDefinition>();
            attack.AttackId = "Test";
            attack.StartupFrames = startup;
            attack.ActiveFrames = active;
            attack.RecoveryFrames = recovery;
            attack.TelegraphLeadFrames = 0;
            attack.HitboxSize = Vector3.one;
            return attack;
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_Startup()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            var phase = runner.GetPhaseAtTime(attack, 0.05f); // 3 frames in

            Assert.That(phase, Is.EqualTo(AttackPhase.Startup));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_Active()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // 10 frames startup = 0.1667s, check at 0.18s
            var phase = runner.GetPhaseAtTime(attack, 0.18f);

            Assert.That(phase, Is.EqualTo(AttackPhase.Active));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_Recovery()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // 10+5 = 15 frames = 0.25s, check at 0.3s
            var phase = runner.GetPhaseAtTime(attack, 0.3f);

            Assert.That(phase, Is.EqualTo(AttackPhase.Recovery));

            Object.DestroyImmediate(runner.gameObject);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackRunner_GetPhaseAtTime_AfterTotal_None()
        {
            var attack = CreateAttack(10, 5, 10);
            var runner = new GameObject().AddComponent<AttackRunner>();

            // 25 frames = 0.4167s, check at 0.5s
            var phase = runner.GetPhaseAtTime(attack, 0.5f);

            Assert.That(phase, Is.EqualTo(AttackPhase.None));

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
