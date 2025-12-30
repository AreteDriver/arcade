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

        #region Negative Path Tests

        [Test]
        public void HitotsumeKozo_TakeDamage_WhenNotVulnerable_StillReducesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            Assert.That(boss.IsVulnerable, Is.False);
            boss.TakeDamage();

            // Current implementation reduces health regardless
            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth - 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_Defeat_WhenAlreadyDefeated_DoesNotFireEventAgain()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();
            int defeatedCount = 0;
            boss.OnDefeated += () => defeatedCount++;

            boss.StartEncounter();
            boss.Defeat();
            boss.Defeat(); // Call again

            Assert.That(defeatedCount, Is.EqualTo(1), "OnDefeated should only fire once");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_ApplyStagger_WhenDefeated_DoesNotChangeState()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();
            boss.Defeat();

            // Try to stagger after defeated
            boss.ApplyStagger(1f);

            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Defeated), "Should remain defeated");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_StartEncounter_ResetsAllState()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();

            boss.StartEncounter();
            boss.ApplyStagger(1f);
            boss.TakeDamage();

            // Restart encounter
            boss.StartEncounter();

            Assert.That(boss.CurrentHealth, Is.EqualTo(3), "Health should reset to max");
            Assert.That(boss.PressureTimer, Is.EqualTo(0f), "Pressure timer should reset");
            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Intro), "State should be Intro");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void HitotsumeKozo_TakeDamage_BelowZero_ClampsToDefeated()
        {
            var go = new GameObject();
            var boss = go.AddComponent<HitotsumeKozoBoss>();
            int defeatedCount = 0;
            boss.OnDefeated += () => defeatedCount++;

            boss.StartEncounter();

            // Damage more times than health allows
            for (int i = 0; i < 5; i++)
            {
                boss.ApplyStagger(1f);
                boss.TakeDamage();
            }

            Assert.That(boss.CurrentHealth, Is.LessThanOrEqualTo(0));
            Assert.That(boss.State, Is.EqualTo(HitotsumeKozoState.Defeated));
            Assert.That(defeatedCount, Is.EqualTo(1), "OnDefeated should only fire once");

            Object.DestroyImmediate(go);
        }

        #endregion
    }
}
