@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Doctor {

    @Id
    @GeneratedValue
    private UUID id;

    private String fullName;

    private String username;
}
