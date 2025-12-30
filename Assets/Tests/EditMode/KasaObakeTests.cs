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
        public void KasaObake_OnHop_EventCanBeSubscribed()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            int eventFireCount = 0;
            int lastHopValue = -1;

            boss.OnHop += (hop) =>
            {
                eventFireCount++;
                lastHopValue = hop;
            };

            // Verify event subscription doesn't throw and initial state is valid
            Assert.That(eventFireCount, Is.EqualTo(0), "Event should not fire on subscription");
            Assert.That(lastHopValue, Is.EqualTo(-1), "Callback should not have been invoked");
            Assert.That(boss.HopCount, Is.EqualTo(0), "Initial hop count should be 0");

            Object.DestroyImmediate(go);
        }

        [Test]
        [NUnit.Framework.Description("Verifies OnHop event fires when hop is triggered. Requires manual invocation since FixedUpdate cannot run in EditMode.")]
        public void KasaObake_OnHop_FiresWhenHopTriggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            int lastHopValue = -1;
            boss.OnHop += (hop) => lastHopValue = hop;

            boss.StartEncounter();

            // Directly invoke the hop to test event wiring (simulating what FixedUpdate would do)
            // This tests the event mechanism without requiring PlayMode
            boss.TriggerHop();

            Assert.That(lastHopValue, Is.EqualTo(1), "OnHop should fire with hop count of 1");
            Assert.That(boss.HopCount, Is.EqualTo(1), "HopCount should increment");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_HasCorrectStateCount()
        {
            // 8 states: Inactive, Intro, Hopping, TongueLash, Spin, Taunt, Staggered, Defeated
            Assert.That(System.Enum.GetValues(typeof(KasaObakeState)).Length, Is.EqualTo(8));
        }

        #region Negative Path Tests

        [Test]
        public void KasaObake_TakeDamage_WhenNotVulnerable_StillReducesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            // Not staggered, so not vulnerable - but TakeDamage is a direct call
            // This tests the implementation behavior (not guarded by IsVulnerable)
            Assert.That(boss.IsVulnerable, Is.False);
            boss.TakeDamage();

            // Current implementation reduces health regardless of state
            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth - 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_Defeat_WhenAlreadyDefeated_DoesNotFireEventAgain()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            int defeatedCount = 0;
            boss.OnDefeated += () => defeatedCount++;

            boss.StartEncounter();
            boss.Defeat();
            boss.Defeat(); // Call again

            // TransitionTo guards against same-state transitions
            Assert.That(defeatedCount, Is.EqualTo(1), "OnDefeated should only fire once");
            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Defeated));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_ApplyStagger_WithZeroDuration_TransitionsToStaggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();

            boss.StartEncounter();
            boss.ApplyStagger(0f);

            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Staggered));
            Assert.That(boss.IsVulnerable, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_TriggerHop_WhenDefeated_DoesNothing()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            int hopCount = 0;
            boss.OnHop += (_) => hopCount++;

            boss.StartEncounter();
            boss.Defeat();

            // Try to hop after defeated
            boss.TriggerHop();

            Assert.That(hopCount, Is.EqualTo(0), "Should not hop when defeated");
            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Defeated));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void KasaObake_TriggerHop_WhenStaggered_DoesNothing()
        {
            var go = new GameObject();
            var boss = go.AddComponent<KasaObakeBoss>();
            int hopCount = 0;
            boss.OnHop += (_) => hopCount++;

            boss.StartEncounter();
            boss.ApplyStagger(1f);

            // Try to hop while staggered
            boss.TriggerHop();

            Assert.That(hopCount, Is.EqualTo(0), "Should not hop when staggered");
            Assert.That(boss.State, Is.EqualTo(KasaObakeState.Staggered));

            Object.DestroyImmediate(go);
        }

        #endregion
    }
}
