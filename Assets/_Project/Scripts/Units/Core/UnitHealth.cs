using System;
using UnityEngine;

namespace DustRTS.Units.Core
{
    /// <summary>
    /// Manages unit health, damage, and death.
    /// </summary>
    public class UnitHealth : MonoBehaviour
    {
        [Header("Health")]
        [SerializeField] private int maxHealth = 100;
        [SerializeField] private int currentHealth;

        [Header("Armor")]
        [SerializeField] private float armor = 0f;

        [Header("Regeneration")]
        [SerializeField] private bool canRegenerate = false;
        [SerializeField] private float regenPerSecond = 0f;
        [SerializeField] private float regenDelay = 5f;

        [Header("State")]
        [SerializeField] private bool isInvulnerable = false;

        private float lastDamageTime;

        public int MaxHealth => maxHealth;
        public int CurrentHealth => currentHealth;
        public float HealthPercent => (float)currentHealth / maxHealth;
        public bool IsAlive => currentHealth > 0;
        public bool IsDamaged => currentHealth < maxHealth;
        public float Armor => armor;

        public event Action OnDeath;
        public event Action<int, int> OnHealthChanged; // current, max
        public event Action<int, DamageType, Vector3> OnDamaged; // amount, type, direction

        public void Initialize(int health, float armorValue = 0f)
        {
            maxHealth = health;
            currentHealth = health;
            armor = armorValue;
        }

        public void Initialize(UnitData data)
        {
            maxHealth = data.maxHealth;
            currentHealth = maxHealth;
            armor = data.armor;
            canRegenerate = data.canRegenerate;
            regenPerSecond = data.regenPerSecond;
        }

        private void Update()
        {
            if (!IsAlive) return;

            if (canRegenerate && IsDamaged)
            {
                UpdateRegeneration();
            }
        }

        private void UpdateRegeneration()
        {
            if (Time.time - lastDamageTime < regenDelay) return;

            float regenAmount = regenPerSecond * Time.deltaTime;
            Heal(Mathf.CeilToInt(regenAmount));
        }

        public void TakeDamage(int amount, DamageType type = DamageType.Kinetic, Vector3 direction = default)
        {
            if (!IsAlive || isInvulnerable) return;
            if (amount <= 0) return;

            // Apply armor reduction
            float reduction = armor / (armor + 100f); // Diminishing returns formula
            int finalDamage = Mathf.Max(1, Mathf.RoundToInt(amount * (1f - reduction)));

            currentHealth -= finalDamage;
            currentHealth = Mathf.Max(0, currentHealth);
            lastDamageTime = Time.time;

            OnDamaged?.Invoke(finalDamage, type, direction);
            OnHealthChanged?.Invoke(currentHealth, maxHealth);

            if (currentHealth <= 0)
            {
                Die();
            }
        }

        public void TakeDamageRaw(int amount)
        {
            if (!IsAlive || isInvulnerable) return;
            if (amount <= 0) return;

            currentHealth -= amount;
            currentHealth = Mathf.Max(0, currentHealth);
            lastDamageTime = Time.time;

            OnHealthChanged?.Invoke(currentHealth, maxHealth);

            if (currentHealth <= 0)
            {
                Die();
            }
        }

        public void Heal(int amount)
        {
            if (!IsAlive) return;
            if (amount <= 0) return;

            currentHealth += amount;
            currentHealth = Mathf.Min(currentHealth, maxHealth);

            OnHealthChanged?.Invoke(currentHealth, maxHealth);
        }

        public void HealToFull()
        {
            currentHealth = maxHealth;
            OnHealthChanged?.Invoke(currentHealth, maxHealth);
        }

        public void SetInvulnerable(bool invulnerable)
        {
            isInvulnerable = invulnerable;
        }

        public void SetMaxHealth(int newMax, bool healToFull = false)
        {
            maxHealth = newMax;
            if (healToFull)
            {
                currentHealth = maxHealth;
            }
            else
            {
                currentHealth = Mathf.Min(currentHealth, maxHealth);
            }
            OnHealthChanged?.Invoke(currentHealth, maxHealth);
        }

        public void ModifyArmor(float delta)
        {
            armor += delta;
            armor = Mathf.Max(0, armor);
        }

        private void Die()
        {
            OnDeath?.Invoke();
        }

        public void Kill()
        {
            if (!IsAlive) return;

            currentHealth = 0;
            OnHealthChanged?.Invoke(currentHealth, maxHealth);
            Die();
        }

        public void Revive(float healthPercent = 1f)
        {
            currentHealth = Mathf.RoundToInt(maxHealth * healthPercent);
            currentHealth = Mathf.Max(1, currentHealth);
            OnHealthChanged?.Invoke(currentHealth, maxHealth);
        }
    }
}
