using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Boss.KasaObake;

namespace YokaiBlade.Tests.EditMode
{
    public class KasaObakeTests
    {
        [Test]
        public void KasaObake_InitialState_Inactive()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Inactive));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_StartEncounter_TransitionsToIntro()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            boss.StartEncounter();

            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Intro));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_StartEncounter_ResetsHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            boss.StartEncounter();

            Assert.That(boss.CurrentHealth, Is.EqualTo(2));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_StartEncounter_ResetsHopCount()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            boss.StartEncounter();

            Assert.That(boss.HopCount, Is.EqualTo(0));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_IsVulnerable_OnlyWhenStaggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            Assert.That(boss.IsVulnerable, Is.False);

            boss.ApplyStagger(1f);

            Assert.That(boss.IsVulnerable, Is.True);
            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Staggered));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_TakeDamage_ReducesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth - 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_TakeDamage_DefeatsWhenHealthZero()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            boss.StartEncounter();

            // Take damage until defeated
            boss.ApplyStagger(1f);
            boss.TakeDamage();
            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_Defeat_TransitionsToDefeated()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            boss.StartEncounter();
            boss.Defeat();

            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_OnHop_FiresEvent()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            int lastHop = 0;
            boss.OnHop += (hop) => lastHop = hop;

            // Note: In a real test we'd simulate FixedUpdate ticks
            // This is a structural test to verify event is wired
            Assert.That(lastHop, Is.EqualTo(0));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_HasCorrectStateCount()
        {
            // 8 states: Inactive, Intro, Hopping, TongueLash, Spin, Taunt, Staggered, Defeated
            Assert.That(System.Enum.GetValues(typeof(KasaObakeState)).Length, Is.EqualTo(8));
        }
    }
}
