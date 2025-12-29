using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Boss.HitotsumeKozo;

namespace YokaiBlade.Tests.EditMode
{
    public class HitotsumeKozoTests
    {
        [Test]
        public void HitotsumeKozo_InitialState_Inactive()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Inactive));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_StartEncounter_TransitionsToIntro()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();

            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Intro));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_StartEncounter_ResetsHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();

            Assert.That(boss.CurrentHealth, Is.EqualTo(3));
            Assert.That(boss.MaxHealth, Is.EqualTo(3));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_StartEncounter_ResetsPressureTimer()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();

            Assert.That(boss.PressureTimer, Is.EqualTo(0f));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_IsVulnerable_OnlyWhenStaggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            Assert.That(boss.IsVulnerable, Is.False);

            boss.ApplyStagger(1f);

            Assert.That(boss.IsVulnerable, Is.True);
            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Staggered));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_TakeDamage_ReducesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth - 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_TakeDamage_ResetsPressureTimer()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();
            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.PressureTimer, Is.EqualTo(0f));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_TakeDamage_DefeatsWhenHealthZero()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            boss.StartEncounter();

            // Take damage until defeated (3 HP)
            boss.ApplyStagger(1f);
            boss.TakeDamage();
            boss.ApplyStagger(1f);
            boss.TakeDamage();
            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_Defeat_TransitionsToDefeated()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            boss.StartEncounter();
            boss.Defeat();

            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_HasCorrectStateCount()
        {
            // 9 states: Inactive, Intro, Flee, Taunt, Cornered, PanicSwipe, Regenerate, Staggered, Defeated
            Assert.That(System.Enum.GetValues(typeof(HitotsumeKozoState)).Length, Is.EqualTo(9));
        }
    }
}
